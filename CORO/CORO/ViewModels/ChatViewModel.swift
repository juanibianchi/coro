import Foundation
import SwiftUI
import SwiftData
import Combine

enum ViewState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}

struct GlobalError: Equatable {
    let message: String
    let code: String?
    let statusCode: Int?
    let retryAfter: Int?
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var displayedPrompt: String = ""
    @Published var selectedModels: Set<String> = []
    @Published var availableModels: [ModelInfo] = []
    @Published var responses: [ModelResponse] = []
    @Published var totalLatency: Int = 0
    @Published var viewState: ViewState = .idle
    @Published var selectedTab: Int = 0
    @Published var conversationHistory: [String: [Message]] = [:]  // Per-model conversation history
    @Published var globalError: GlobalError?
    @Published var pendingCompletionBadges: Set<String> = []
    @Published var searchResults: [APIService.SearchResult] = []
    @Published var isSearchEnabled: Bool {
        didSet {
            if apiService.searchEnabledByDefault != isSearchEnabled {
                apiService.updateSearchDefault(isSearchEnabled)
            }
            if !isSearchEnabled {
                searchResults = []
                lastSearchContext = nil
                lastSearchQuery = nil
            }
        }
    }
    @Published var isSearching: Bool = false

    // Model parameters
    @Published var temperature: Double = 0.7
    @Published var maxTokens: Int = 2000
    @Published var topP: Double? = nil

    let apiService: APIService
    let mlxService: MLXService
    var modelContext: ModelContext?

    // Caching
    private var lastPrompt: String = ""
    private var lastSelectedModels: Set<String> = []
    private var isRestoringConversation = false
    private var hasAutoSelectedFirstReadyResponse = false
    private var userManuallySelectedTab = false
    private var activeConversation: Conversation?
    private var badgeRemovalWorkItems: [String: DispatchWorkItem] = [:]
    private var lastSearchContext: String?
    private var lastSearchQuery: String?
    private var cancellables: Set<AnyCancellable> = []

    struct RequestContext: Sendable {
        let conversationGuide: String?
        let searchPayload: SearchContextPayload?
        let systemPrompt: String?
        let searchSection: String?
    }

    // On-device model IDs
    private let onDeviceModelIds = ["llama-3.2-1b-local"]
    private let placeholderText = "Awaiting response..."
    private let modelDisplayOrder = [
        "gemini",
        "cerebras-llama-3.1-8b",
        "cerebras-llama-3.3-70b",
        "cerebras-gpt-oss-120b",
        "cerebras-qwen-3-32b",
        "llama-70b",
        "llama-8b",
        "mixtral",
        "deepseek",
        "llama-3.2-1b-local"
    ]
    private let pendingAssistantPlaceholder = Message.pendingAssistantPlaceholder

    init(apiService: APIService? = nil, mlxService: MLXService? = nil) {
        self.apiService = apiService ?? APIService()
        self.mlxService = mlxService ?? MLXService()
        isSearchEnabled = self.apiService.searchEnabledByDefault
        loadDefaultModels()

        self.apiService.$searchEnabledByDefault
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                if self.isSearchEnabled != newValue {
                    self.isSearchEnabled = newValue
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Load Available Models

    func loadAvailableModels() async {
        do {
            var models = try await apiService.fetchAvailableModels()

            // Always add the on-device model to the list
            let onDeviceModel = ModelInfo(
                id: "llama-3.2-1b-local",
                name: "Llama 3.2 1B (On-Device)",
                provider: "Local",
                cost: "free"
            )
            models.append(onDeviceModel)

            // Sort models by a predefined order to keep consistency
            models.sort { model1, model2 in
                let index1 = modelDisplayOrder.firstIndex(of: model1.id) ?? Int.max
                let index2 = modelDisplayOrder.firstIndex(of: model2.id) ?? Int.max
                return index1 < index2
            }

            self.availableModels = models

            // Select free cloud models by default if no selection
            if selectedModels.isEmpty {
                let defaultModels = models.filter { !$0.isPremium && !onDeviceModelIds.contains($0.id) }
                selectedModels = Set(defaultModels.map { $0.id })
            }
        } catch {
            print("Failed to load models: \(error)")
            // Use fallback models
            loadDefaultModels()
        }
    }

    private func loadDefaultModels() {
        // Fallback models if API fails
        availableModels = [
            ModelInfo(id: "gemini", name: "Gemini 2.5 Flash", provider: "Google", cost: "free"),
            ModelInfo(id: "cerebras-llama-3.1-8b", name: "Cerebras Llama 3.1 8B", provider: "Cerebras", cost: "fast"),
            ModelInfo(id: "cerebras-llama-3.3-70b", name: "Cerebras Llama 3.3 70B", provider: "Cerebras", cost: "fast"),
            ModelInfo(id: "cerebras-gpt-oss-120b", name: "Cerebras GPT-OSS 120B", provider: "Cerebras", cost: "fast"),
            ModelInfo(id: "cerebras-qwen-3-32b", name: "Cerebras Qwen 3 32B", provider: "Cerebras", cost: "fast"),
            ModelInfo(id: "llama-70b", name: "Llama 3.3 70B", provider: "Groq", cost: "free"),
            ModelInfo(id: "llama-8b", name: "Llama 3.1 8B", provider: "Groq", cost: "free"),
            ModelInfo(id: "mixtral", name: "Llama 4 Maverick", provider: "Groq", cost: "free"),
            ModelInfo(id: "llama-3.2-1b-local", name: "Llama 3.2 1B (On-Device)", provider: "Local", cost: "free")
        ]

        // Select cloud models by default
        selectedModels = Set(availableModels.filter { !onDeviceModelIds.contains($0.id) }.map { $0.id })
    }

    // MARK: - Send Chat Request

    func sendChatRequest() async {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedPrompt.isEmpty else {
            viewState = .error("Please enter a prompt")
            return
        }

        guard !selectedModels.isEmpty else {
            viewState = .error("Please select at least one model")
            return
        }

        if trimmedPrompt == lastPrompt && selectedModels == lastSelectedModels && !responses.isEmpty {
            displayedPrompt = trimmedPrompt
            viewState = .success
            return
        }

        globalError = nil
        pendingCompletionBadges.removeAll()
        userManuallySelectedTab = false
        clearScheduledBadgeRemovals()

        let context = await prepareContext(for: trimmedPrompt)

        viewState = .loading
        responses = []
        selectedTab = 0
        hasAutoSelectedFirstReadyResponse = false

        let models = orderedModelIds(from: Array(selectedModels))
        let historySnapshots = models.reduce(into: [String: [Message]]()) { result, modelId in
            result[modelId] = conversationHistory[modelId] ?? []
        }
        let overridesDictionary = apiService.modelAPIKeys.overridesDictionary

        displayedPrompt = trimmedPrompt
        prompt = ""

        // Seed placeholders
        responses = models.map { modelId in
            ModelResponse(
                model: modelId,
                response: placeholderText,
                tokens: nil,
                latencyMs: 0,
                error: nil,
                errorCode: nil
            )
        }
        selectedTab = 0
        totalLatency = 0

        // Append user prompt to conversation history snapshot
        for modelId in models {
            if conversationHistory[modelId] == nil {
                conversationHistory[modelId] = []
            }
            conversationHistory[modelId]?.append(Message(role: "user", content: trimmedPrompt))
            conversationHistory[modelId]?.append(Message(role: "assistant", content: pendingAssistantPlaceholder))
        }

        // Transition to results view immediately
        viewState = .success

        let temperatureValue = temperature
        let maxTokensValue = maxTokens
        let topPValue = topP
        let overallStart = Date()

        lastPrompt = trimmedPrompt
        lastSelectedModels = selectedModels

        await withTaskGroup(of: (String, Result<ModelResponse, Error>).self) { group in
            for modelId in models {
                if onDeviceModelIds.contains(modelId) {
                    let history = historySnapshots[modelId] ?? []
                    group.addTask {
                        do {
                            let response = try await self.mlxService.generate(
                                prompt: trimmedPrompt,
                                temperature: Float(temperatureValue),
                                maxTokens: maxTokensValue,
                                conversationHistory: history,
                                systemPrompt: context.systemPrompt
                            )
                            return (modelId, .success(response))
                        } catch {
                            return (modelId, .failure(error))
                        }
                    }
                } else {
                    let history = historySnapshots[modelId] ?? []
                    group.addTask {
                        do {
                            let conversationPayload = history.isEmpty ? nil : [modelId: history]
                            let request = ChatRequest(
                                prompt: trimmedPrompt,
                                models: [modelId],
                                temperature: temperatureValue,
                                maxTokens: maxTokensValue,
                                topP: topPValue,
                                conversationHistory: conversationPayload,
                                apiOverrides: overridesDictionary.isEmpty ? nil : overridesDictionary,
                                conversationGuide: context.conversationGuide,
                                searchContext: context.searchPayload
                            )

                            let result = try await self.apiService.sendChatRequest(request)
                            guard let response = result.responses.first else {
                                throw NSError(domain: "ChatViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty response"])
                            }
                            return (modelId, .success(response))
                        } catch {
                            return (modelId, .failure(error))
                        }
                    }
                }
            }

            for await (modelId, result) in group {
                switch result {
                case .success(let response):
                    let currentSelectedModelId = responses.indices.contains(selectedTab) ? responses[selectedTab].model : nil

                    if let index = responses.firstIndex(where: { $0.model == modelId }) {
                        responses[index] = response
                    } else {
                        responses.append(response)
                    }
                    selectFirstAvailableResponseIfNeeded()

                    if response.error == nil {
                        replacePendingAssistantMessage(for: modelId, with: response.response)
                    } else {
                        replacePendingAssistantMessage(for: modelId, with: response.userFriendlyError)
                    }

                    cancelBadgeRemoval(for: modelId)
                    if let selectedModel = currentSelectedModelId,
                       selectedModel != modelId,
                       userManuallySelectedTab {
                        pendingCompletionBadges.insert(modelId)
                        scheduleBadgeRemoval(for: modelId)
                    } else {
                        pendingCompletionBadges.remove(modelId)
                    }

                    totalLatency = max(totalLatency, response.latencyMs)

                    if !responses.contains(where: { $0.hasError }) {
                        globalError = nil
                    }

                case .failure(let error):
                    let currentSelectedModelId = responses.indices.contains(selectedTab) ? responses[selectedTab].model : nil
                    let failureLatency = Int(Date().timeIntervalSince(overallStart) * 1000)
                    let (errorResponse, banner) = makeErrorResponse(for: modelId, error: error, latencyMs: failureLatency)

                    if let index = responses.firstIndex(where: { $0.model == modelId }) {
                        responses[index] = errorResponse
                    } else {
                        responses.append(errorResponse)
                    }

                    selectFirstAvailableResponseIfNeeded()
                    replacePendingAssistantMessage(for: modelId, with: errorResponse.userFriendlyError)
                    if let selectedModel = currentSelectedModelId,
                       selectedModel != modelId,
                       userManuallySelectedTab {
                        pendingCompletionBadges.insert(modelId)
                        scheduleBadgeRemoval(for: modelId)
                    }

                    if globalError == nil, let banner {
                        globalError = banner
                    }

                    totalLatency = max(totalLatency, failureLatency)
                }
            }
        }

        let elapsedMs = Int(Date().timeIntervalSince(overallStart) * 1000)
        totalLatency = max(totalLatency, elapsedMs)

        saveConversation()

        // Haptic feedback once all models completed
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - Retry Failed Model

    func retryFailedModel(_ modelId: String) async {
        guard let failedResponse = responses.first(where: { $0.model == modelId && $0.hasError }) else {
            return
        }

        // Find the index of the failed response
        guard let index = responses.firstIndex(where: { $0.id == failedResponse.id }) else {
            return
        }

        let retryStart = Date()

        do {
            // Get conversation history for this model
            let history = conversationHistory[modelId] ?? []
            let overrides = apiService.modelAPIKeys.overridesDictionary
            let context = await prepareContext(for: displayedPrompt)

            let newResponse: ModelResponse
            if onDeviceModelIds.contains(modelId) {
                newResponse = try await mlxService.generate(
                    prompt: displayedPrompt,
                    temperature: Float(temperature),
                    maxTokens: maxTokens,
                    conversationHistory: history,
                    systemPrompt: context.systemPrompt
                )
            } else {
                let request = ChatRequest(
                    prompt: displayedPrompt,
                    models: [modelId],
                    temperature: temperature,
                    maxTokens: maxTokens,
                    topP: topP,
                    conversationHistory: history.isEmpty ? nil : [modelId: history],
                    apiOverrides: overrides.isEmpty ? nil : overrides,
                    conversationGuide: context.conversationGuide,
                    searchContext: context.searchPayload
                )

                let result = try await apiService.sendChatRequest(request)
                guard let response = result.responses.first else {
                    throw NSError(domain: "ChatViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response received"])
                }
                newResponse = response
            }

            responses[index] = newResponse
            replacePendingAssistantMessage(for: modelId, with: newResponse.error == nil ? newResponse.response : newResponse.userFriendlyError)

            cancelBadgeRemoval(for: modelId)
            if let selectedModel = responses.indices.contains(selectedTab) ? responses[selectedTab].model : nil,
               selectedModel != modelId,
               userManuallySelectedTab {
                pendingCompletionBadges.insert(modelId)
                scheduleBadgeRemoval(for: modelId)
            } else {
                pendingCompletionBadges.remove(modelId)
            }

            saveConversation()

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(newResponse.hasError ? .warning : .success)

            if !responses.contains(where: { $0.hasError }) {
                globalError = nil
            }

        } catch {
            let failureLatency = Int(Date().timeIntervalSince(retryStart) * 1000)
            let (errorResponse, banner) = makeErrorResponse(for: modelId, error: error, latencyMs: failureLatency)
            responses[index] = errorResponse
            replacePendingAssistantMessage(for: modelId, with: errorResponse.userFriendlyError)

            if globalError == nil, let banner {
                globalError = banner
            }

            pendingCompletionBadges.insert(modelId)
            scheduleBadgeRemoval(for: modelId)

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    // MARK: - Model Selection

    func toggleModel(_ modelId: String) {
        if selectedModels.contains(modelId) {
            selectedModels.remove(modelId)
        } else {
            selectedModels.insert(modelId)
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func selectAllModels() {
        selectedModels = Set(availableModels.map { $0.id })

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func deselectAllModels() {
        selectedModels.removeAll()

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func userSelectedTab(_ index: Int) {
        userManuallySelectedTab = true
        if responses.indices.contains(index) {
            let modelId = responses[index].model
            pendingCompletionBadges.remove(modelId)
            cancelBadgeRemoval(for: modelId)
        }
        selectedTab = index
    }

    // MARK: - Copy to Clipboard

    func copyResponse(_ response: ModelResponse) {
        UIPasteboard.general.string = response.response

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func copyAllResponses() {
        let allText = responses.map { response in
            "### \(getModelName(response.model))\n\(response.response)"
        }.joined(separator: "\n\n---\n\n")

        UIPasteboard.general.string = allText

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - Context Preparation

    private func prepareContext(for query: String) async -> RequestContext {
        await runSearchIfNeeded(for: query)
        return buildRequestContext()
    }

    private func runSearchIfNeeded(for query: String) async {
        guard isSearchEnabled else {
            searchResults = []
            lastSearchContext = nil
            lastSearchQuery = nil
            isSearching = false
            return
        }

        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            searchResults = []
            lastSearchContext = nil
            lastSearchQuery = nil
            isSearching = false
            return
        }

        if normalizedQuery == lastSearchQuery, !searchResults.isEmpty {
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            let results = try await apiService.performSearch(query: normalizedQuery)
            searchResults = results
            lastSearchQuery = normalizedQuery
        } catch {
            print("Search error: \(error.localizedDescription)")
            searchResults = []
            lastSearchQuery = nil
            lastSearchContext = nil
        }
    }

    private func buildRequestContext() -> RequestContext {
        let trimmedGuide = apiService.conversationGuide.trimmingCharacters(in: .whitespacesAndNewlines)
        let guide = trimmedGuide.isEmpty ? nil : trimmedGuide

        let payload: SearchContextPayload?
        if let query = lastSearchQuery, !searchResults.isEmpty {
            let snippets = searchResults.map {
                SearchResultSnippet(title: $0.title, snippet: $0.snippet, url: $0.url)
            }
            payload = SearchContextPayload(query: query, results: snippets)
        } else {
            payload = nil
        }

        let searchSection = buildSearchSection(from: payload)
        lastSearchContext = searchSection

        let systemPrompt = composeSystemPrompt(conversationGuide: guide, searchSection: searchSection)

        return RequestContext(
            conversationGuide: guide,
            searchPayload: payload,
            systemPrompt: systemPrompt,
            searchSection: searchSection
        )
    }

    private func buildSearchSection(from payload: SearchContextPayload?) -> String? {
        guard let payload, !payload.results.isEmpty else { return nil }

        let lines = payload.results.enumerated().map { index, result -> String in
            let title = result.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let snippet = result.snippet.trimmingCharacters(in: .whitespacesAndNewlines)
            let url = result.url.trimmingCharacters(in: .whitespacesAndNewlines)
            return "[S\(index + 1)] \(title)\n\(snippet)\nSource: \(url)"
        }.filter { !$0.isEmpty }

        guard !lines.isEmpty else { return nil }

        let query = payload.query.trimmingCharacters(in: .whitespacesAndNewlines)
        let header = query.isEmpty ? "Web Search Findings:" : "Web Search Findings for \"\(query)\":"

        return header + "\n" + lines.joined(separator: "\n\n") + "\n\nWhen referencing these sources, cite them inline as [S1], [S2], etc."
    }

    private func composeSystemPrompt(conversationGuide: String?, searchSection: String?) -> String? {
        var sections: [String] = []

        if let guide = conversationGuide, !guide.isEmpty {
            sections.append("Conversation Guide:\n\(guide)")
        }

        if let searchSection, !searchSection.isEmpty {
            sections.append(searchSection)
        }

        guard !sections.isEmpty else { return nil }

        let header = "You are contributing one perspective within CORO, an app that gathers diverse AI viewpoints. Offer thoughtful, well-reasoned answers that complement other assistants, and respect the guidance and context below."

        return ([header] + sections).joined(separator: "\n\n")
    }

    // MARK: - Helpers

    func getModelName(_ modelId: String) -> String {
        availableModels.first { $0.id == modelId }?.name ?? modelId
    }

    func getModelColor(_ modelId: String) -> Color {
        AppTheme.Colors.modelAccent(for: modelId)
    }

    private func orderedModelIds(from models: [String]) -> [String] {
        var ordered = availableModels.map(\.id).filter { models.contains($0) }

        // Append any models not present in availableModels (fallback)
        let remaining = models.filter { !ordered.contains($0) }
        if !remaining.isEmpty {
            ordered.append(contentsOf: remaining.sorted())
        }

        return ordered
    }

    private func selectFirstAvailableResponseIfNeeded() {
        guard !hasAutoSelectedFirstReadyResponse else { return }
        guard !userManuallySelectedTab else { return }

        if !responses.indices.contains(selectedTab) {
            if let firstReady = responses.firstIndex(where: { $0.response != placeholderText || $0.hasError }) {
                selectedTab = firstReady
                hasAutoSelectedFirstReadyResponse = true
            }
            return
        }

        let currentResponse = responses[selectedTab]
        if currentResponse.response == placeholderText {
            if let firstSuccess = responses.firstIndex(where: { $0.response != placeholderText && !$0.hasError }) {
                selectedTab = firstSuccess
                hasAutoSelectedFirstReadyResponse = true
            } else if let firstResolved = responses.firstIndex(where: { $0.response != placeholderText || $0.hasError }) {
                selectedTab = firstResolved
                hasAutoSelectedFirstReadyResponse = true
            }
        }
    }

    private func replacePendingAssistantMessage(for modelId: String, with content: String) {
        guard var messages = conversationHistory[modelId] else { return }

        if let index = messages.lastIndex(where: { $0.content == pendingAssistantPlaceholder }) {
            messages[index] = Message(role: "assistant", content: content)
        } else {
            messages.append(Message(role: "assistant", content: content))
        }

        conversationHistory[modelId] = messages
    }

    private func normalizedErrorCode(from code: String?, statusCode: Int?, message: String) -> String? {
        if let code = code, !code.isEmpty {
            return code
        }

        if let status = statusCode {
            switch status {
            case 401, 403:
                return "unauthorized"
            case 408:
                return "timeout"
            case 429:
                return "rate_limited"
            case 500...599:
                return "service_unavailable"
            default:
                break
            }
        }

        let lowercased = message.lowercased()
        if lowercased.contains("api key") || lowercased.contains("unauthorized") {
            return "unauthorized"
        }
        if lowercased.contains("rate limit") {
            return "rate_limited"
        }
        if lowercased.contains("timeout") {
            return "timeout"
        }
        if lowercased.contains("network") || lowercased.contains("connection") {
            return "network_error"
        }
        if lowercased.contains("service unavailable") {
            return "service_unavailable"
        }

        return nil
    }

    private func makeGlobalError(from error: APIError) -> GlobalError {
        switch error {
        case .serverError(let message, let code, let statusCode, let retryAfter):
            let normalized = normalizedErrorCode(from: code, statusCode: statusCode, message: message)
            let friendly = normalized.map { ErrorCodeHelper.getUserFriendlyMessage(for: $0, originalMessage: message) } ?? message
            return GlobalError(message: friendly, code: normalized, statusCode: statusCode, retryAfter: retryAfter)

        case .networkError(let underlying):
            let friendly = ErrorCodeHelper.getUserFriendlyMessage(for: "network_error", originalMessage: underlying.localizedDescription)
            return GlobalError(message: friendly, code: "network_error", statusCode: nil, retryAfter: nil)

        case .invalidURL:
            let friendly = ErrorCodeHelper.getUserFriendlyMessage(for: "invalid_request", originalMessage: "Invalid API URL. Please check settings.")
            return GlobalError(message: friendly, code: "invalid_request", statusCode: nil, retryAfter: nil)

        case .invalidResponse:
            let friendly = ErrorCodeHelper.getUserFriendlyMessage(for: "service_unavailable", originalMessage: "Received an unexpected response from the server.")
            return GlobalError(message: friendly, code: "service_unavailable", statusCode: nil, retryAfter: nil)

        case .decodingError:
            let friendly = ErrorCodeHelper.getUserFriendlyMessage(for: "internal_error", originalMessage: "Failed to parse server response.")
            return GlobalError(message: friendly, code: "internal_error", statusCode: nil, retryAfter: nil)
        }
    }

    private func makeErrorResponse(for modelId: String, error: Error, latencyMs: Int) -> (ModelResponse, GlobalError?) {
        if let apiError = error as? APIError {
            let global = makeGlobalError(from: apiError)
            let errorCode = global.code ?? "unknown_error"
            let response = ModelResponse(
                model: modelId,
                response: "",
                tokens: nil,
                latencyMs: latencyMs,
                error: global.message,
                errorCode: errorCode
            )
            return (response, global)
        }

        let message = error.localizedDescription
        let response = ModelResponse(
            model: modelId,
            response: "",
            tokens: nil,
            latencyMs: latencyMs,
            error: message,
            errorCode: "unknown_error"
        )
        let global = GlobalError(
            message: message,
            code: "unknown_error",
            statusCode: nil,
            retryAfter: nil
        )
        return (response, global)
    }

    private func shouldAutoRetry(_ response: ModelResponse) -> Bool {
        guard response.hasError else { return false }

        if let code = response.errorCode?.lowercased(),
           ["authentication_failed", "api_key_missing", "api_key_invalid", "unauthorized"].contains(code) {
            return true
        }

        let message = response.error?.lowercased() ?? ""
        return message.contains("unauthorized") || message.contains("authentication") || message.contains("api key")
    }

    private func hasCredentialChanges() -> Bool {
        !apiService.apiToken.isEmpty || apiService.modelAPIKeys.hasAnyKeys
    }

    private func autoRetryRecoverableErrorsIfPossible() async {
        guard hasCredentialChanges() else { return }

        let recoverable = responses.filter { shouldAutoRetry($0) }
        guard !recoverable.isEmpty else { return }

        for response in recoverable {
            await retryFailedModel(response.model)
        }

        await MainActor.run {
            saveConversation()
            let remainingIssues = responses.contains { shouldAutoRetry($0) }
            if !remainingIssues {
                globalError = nil
            }
        }
    }

    func returnToPrompt() {
        viewState = .idle
        prompt = ""
        displayedPrompt = ""
        responses = []
        totalLatency = 0
        hasAutoSelectedFirstReadyResponse = false
        conversationHistory = [:]
        globalError = nil
        pendingCompletionBadges.removeAll()
        userManuallySelectedTab = false
    }

    var canSubmit: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedModels.isEmpty
    }

    // MARK: - Conversation History

    func saveConversation() {
        guard let modelContext = modelContext,
              !responses.isEmpty,
              !displayedPrompt.isEmpty,
              !isRestoringConversation else { return }

        // Avoid saving placeholder-only conversations
        guard responses.contains(where: { $0.response != placeholderText || $0.hasError }) else {
            return
        }

        let chatResponse = ChatResponse(
            responses: responses,
            totalLatencyMs: totalLatency
        )

        // Convert conversation history to saved format
        var savedMessages: [SavedConversationMessage] = []
        var messageOrder = 0
        for modelId in conversationHistory.keys.sorted() {
            guard let messages = conversationHistory[modelId] else { continue }
            for message in messages {
                if message.isPendingAssistant {
                    continue
                }
                savedMessages.append(SavedConversationMessage.from(message, modelId: modelId, order: messageOrder))
                messageOrder += 1
            }
        }

        let savedResponses = chatResponse.responses.map { response in
            SavedModelResponse(
                model: response.model,
                response: response.response,
                tokens: response.tokens,
                latencyMs: response.latencyMs,
                error: response.error
            )
        }

        if let existing = activeConversation {
            existing.prompt = displayedPrompt
            existing.totalLatency = totalLatency
            existing.responses = savedResponses
            existing.conversationHistory = savedMessages
        } else {
            let newConversation = Conversation(
                prompt: displayedPrompt,
                totalLatency: totalLatency,
                responses: savedResponses,
                conversationHistory: savedMessages
            )
            modelContext.insert(newConversation)
            activeConversation = newConversation
        }

        do {
            try modelContext.save()
            print("✅ Conversation saved successfully with \(savedMessages.count) follow-up messages")
        } catch {
            print("❌ Failed to save conversation: \(error)")
        }
    }

    func loadConversation(_ conversation: Conversation) {
        isRestoringConversation = true
        defer { isRestoringConversation = false }

        pendingCompletionBadges.removeAll()
        userManuallySelectedTab = false
        clearScheduledBadgeRemovals()

        let savedResponses = conversation.responses.map { $0.toModelResponse() }
        let responseModels = savedResponses.map { $0.model }
        let orderedModels = orderedModelIds(from: responseModels)

        self.prompt = ""
        self.displayedPrompt = conversation.prompt
        self.responses = orderedModels.compactMap { modelId in
            savedResponses.first(where: { $0.model == modelId })
        }
        self.selectedModels = Set(orderedModels)
        self.totalLatency = conversation.totalLatency
        self.viewState = .success
        self.selectedTab = 0
        hasAutoSelectedFirstReadyResponse = false
        selectFirstAvailableResponseIfNeeded()
        hasAutoSelectedFirstReadyResponse = true
        activeConversation = conversation

        // Restore conversation history from saved messages
        var restoredHistory: [String: [Message]] = [:]
        let historyCollection = conversation.conversationHistory
        let sortedHistory: [SavedConversationMessage]
        if historyCollection.allSatisfy({ $0.orderIndex == 0 }) {
            sortedHistory = Array(historyCollection)
        } else {
            sortedHistory = historyCollection.sorted { $0.orderIndex < $1.orderIndex }
        }
        for savedMessage in sortedHistory {
            let message = savedMessage.toMessage()
            if restoredHistory[savedMessage.modelId] == nil {
                restoredHistory[savedMessage.modelId] = []
            }
            restoredHistory[savedMessage.modelId]?.append(message)
        }
        self.conversationHistory = restoredHistory

        print("📥 Loaded conversation with \(conversation.conversationHistory.count) follow-up messages")

        // Update cache when loading conversation
        lastPrompt = conversation.prompt
        lastSelectedModels = selectedModels

        Task {
            await autoRetryRecoverableErrorsIfPossible()
        }
    }

    func startNewChat() {
        prompt = ""
        displayedPrompt = ""
        responses = []
        viewState = .idle
        selectedTab = 0
        totalLatency = 0
        conversationHistory = [:]
        activeConversation = nil
        globalError = nil
        pendingCompletionBadges.removeAll()
        userManuallySelectedTab = false
        searchResults = []
        lastSearchContext = nil
        lastSearchQuery = nil

        // Clear cache
        lastPrompt = ""
        lastSelectedModels = []
        hasAutoSelectedFirstReadyResponse = false
    }

    // MARK: - Follow-up Messages

    func sendFollowUpMessage(to modelId: String, message: String, contextOverride: RequestContext? = nil) async {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        if conversationHistory[modelId] == nil {
            conversationHistory[modelId] = []
        }

        pendingCompletionBadges.remove(modelId)

        var historyForRequest = conversationHistory[modelId] ?? []
        historyForRequest.append(Message(role: "user", content: trimmed))
        conversationHistory[modelId] = historyForRequest
        conversationHistory[modelId]?.append(Message(role: "assistant", content: pendingAssistantPlaceholder))

        // Create a temporary loading state for this model
        if let index = responses.firstIndex(where: { $0.model == modelId }) {
            // Update existing response to show loading
            let updatedResponse = responses[index]
            responses[index] = ModelResponse(
                model: modelId,
                response: updatedResponse.response,
                tokens: updatedResponse.tokens,
                latencyMs: updatedResponse.latencyMs,
                error: nil,
                errorCode: nil
            )
        }

        let context: RequestContext
        if let override = contextOverride {
            context = override
        } else {
            context = await prepareContext(for: trimmed)
        }

        do {
            let newResponse: ModelResponse

            // Check if this is an on-device model
            if onDeviceModelIds.contains(modelId) {
                // Use MLX service for on-device model
                let history = historyForRequest
                newResponse = try await mlxService.generate(
                    prompt: trimmed,
                    temperature: 0.7,
                    maxTokens: 512,
                    conversationHistory: history,
                    systemPrompt: context.systemPrompt
                )
            } else {
                // Use API service for cloud models
                var historyForModel: [String: [Message]] = [:]
                historyForModel[modelId] = historyForRequest

                let overrides = apiService.modelAPIKeys.overridesDictionary
                let request = ChatRequest(
                    prompt: trimmed,
                    models: [modelId],
                    temperature: temperature,
                    maxTokens: maxTokens,
                    topP: topP,
                    conversationHistory: historyForModel.isEmpty ? nil : historyForModel,
                    apiOverrides: overrides.isEmpty ? nil : overrides,
                    conversationGuide: context.conversationGuide,
                    searchContext: context.searchPayload
                )

                let result = try await apiService.sendChatRequest(request)
                guard let response = result.responses.first else {
                    throw NSError(domain: "ChatViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response received"])
                }
                newResponse = response
            }

            // Update the response for this model
            if let index = responses.firstIndex(where: { $0.model == modelId }) {
                responses[index] = newResponse
            }

            // Update conversation history
            replacePendingAssistantMessage(for: modelId, with: newResponse.error == nil ? newResponse.response : newResponse.userFriendlyError)

            let currentSelectedModelId = responses.indices.contains(selectedTab) ? responses[selectedTab].model : nil
            cancelBadgeRemoval(for: modelId)
            if let selectedModel = currentSelectedModelId,
               selectedModel != modelId,
               userManuallySelectedTab {
                pendingCompletionBadges.insert(modelId)
                scheduleBadgeRemoval(for: modelId)
            } else {
                pendingCompletionBadges.remove(modelId)
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            saveConversation()

            if !responses.contains(where: { $0.hasError }) {
                globalError = nil
            }

        } catch {
            // Handle error
            let (errorResponse, banner) = makeErrorResponse(for: modelId, error: error, latencyMs: 0)

            if let index = responses.firstIndex(where: { $0.model == modelId }) {
                responses[index] = errorResponse
            } else {
                responses.append(errorResponse)
            }

            replacePendingAssistantMessage(for: modelId, with: errorResponse.userFriendlyError)

            if globalError == nil, let banner {
                globalError = banner
            }

            if userManuallySelectedTab {
                pendingCompletionBadges.insert(modelId)
                scheduleBadgeRemoval(for: modelId)
            }

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

            saveConversation()
        }
    }

    func getConversationMessages(for modelId: String) -> [Message] {
        return conversationHistory[modelId] ?? []
    }

    func sendFollowUpToAllModels(message: String, excluding excludedModelId: String? = nil) async {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let targetResponses = responses.filter { response in
            response.model != excludedModelId
        }

        guard !targetResponses.isEmpty else { return }

        let context = await prepareContext(for: trimmed)

        await withTaskGroup(of: Void.self) { group in
            for response in targetResponses {
                group.addTask {
                    await self.sendFollowUpMessage(
                        to: response.model,
                        message: trimmed,
                        contextOverride: context
                    )
                }
            }
        }
    }

    func indexForModel(_ modelId: String) -> Int? {
        responses.firstIndex(where: { $0.model == modelId })
    }

    private func scheduleBadgeRemoval(for modelId: String) {
        badgeRemovalWorkItems[modelId]?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingCompletionBadges.remove(modelId)
            self.badgeRemovalWorkItems[modelId] = nil
        }
        badgeRemovalWorkItems[modelId] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }

    private func cancelBadgeRemoval(for modelId: String) {
        badgeRemovalWorkItems[modelId]?.cancel()
        badgeRemovalWorkItems[modelId] = nil
    }

    private func clearScheduledBadgeRemovals() {
        badgeRemovalWorkItems.values.forEach { $0.cancel() }
        badgeRemovalWorkItems.removeAll()
    }
}
