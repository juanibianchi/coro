import Foundation
import SwiftUI
import SwiftData

enum ViewState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var selectedModels: Set<String> = []
    @Published var availableModels: [ModelInfo] = []
    @Published var responses: [ModelResponse] = []
    @Published var totalLatency: Int = 0
    @Published var viewState: ViewState = .idle
    @Published var selectedTab: Int = 0
    @Published var conversationHistory: [String: [Message]] = [:]  // Per-model conversation history

    let apiService: APIService
    let mlxService: MLXService
    var modelContext: ModelContext?

    // Caching
    private var lastPrompt: String = ""
    private var lastSelectedModels: Set<String> = []

    // On-device model IDs
    private let onDeviceModelIds = ["llama-3.2-1b-local"]

    init(apiService: APIService = APIService(), mlxService: MLXService = MLXService()) {
        self.apiService = apiService
        self.mlxService = mlxService
        loadDefaultModels()
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
            let modelOrder = ["gemini", "llama-70b", "llama-8b", "mixtral", "deepseek", "llama-3.2-1b-local"]
            models.sort { model1, model2 in
                let index1 = modelOrder.firstIndex(of: model1.id) ?? Int.max
                let index2 = modelOrder.firstIndex(of: model2.id) ?? Int.max
                return index1 < index2
            }

            self.availableModels = models

            // Select all free models by default if no selection
            if selectedModels.isEmpty {
                selectedModels = Set(models.filter { !$0.isPremium }.map { $0.id })
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
            ModelInfo(id: "llama-70b", name: "Llama 3.3 70B", provider: "Groq", cost: "free"),
            ModelInfo(id: "llama-8b", name: "Llama 3.1 8B", provider: "Groq", cost: "free"),
            ModelInfo(id: "mixtral", name: "Llama 4 Maverick", provider: "Groq", cost: "free"),
            ModelInfo(id: "llama-3.2-1b-local", name: "Llama 3.2 1B (On-Device)", provider: "Local", cost: "free")
        ]

        // Select all by default
        selectedModels = Set(availableModels.map { $0.id })
    }

    // MARK: - Send Chat Request

    func sendChatRequest() async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            viewState = .error("Please enter a prompt")
            return
        }

        guard !selectedModels.isEmpty else {
            viewState = .error("Please select at least one model")
            return
        }

        // Check cache - if same prompt and models, reuse existing responses
        if prompt == lastPrompt && selectedModels == lastSelectedModels && !responses.isEmpty {
            viewState = .success
            return
        }

        viewState = .loading
        responses = []
        selectedTab = 0

        do {
            // Separate cloud and on-device models
            let cloudModels = selectedModels.filter { !onDeviceModelIds.contains($0) }
            let localModels = selectedModels.filter { onDeviceModelIds.contains($0) }

            var allResponses: [ModelResponse] = []
            let overallStart = Date()

            // Process cloud models via API
            if !cloudModels.isEmpty {
                let request = ChatRequest(
                    prompt: prompt,
                    models: Array(cloudModels),
                    conversationHistory: conversationHistory.isEmpty ? nil : conversationHistory
                )

                let result = try await apiService.sendChatRequest(request)
                allResponses.append(contentsOf: result.responses)
            }

            // Process on-device models via MLX
            for modelId in localModels {
                let history = conversationHistory[modelId] ?? []
                let response = try await mlxService.generate(
                    prompt: prompt,
                    temperature: 0.7,
                    maxTokens: 512,
                    conversationHistory: history
                )
                allResponses.append(response)
            }

            let totalLatency = Int(Date().timeIntervalSince(overallStart) * 1000)

            self.responses = allResponses
            self.totalLatency = totalLatency
            self.viewState = .success

            // Update conversation history for each model
            for response in allResponses where response.error == nil {
                // Initialize history if needed
                if conversationHistory[response.model] == nil {
                    conversationHistory[response.model] = []
                }

                // Add user message
                conversationHistory[response.model]?.append(Message(role: "user", content: prompt))

                // Add assistant response
                conversationHistory[response.model]?.append(Message(role: "assistant", content: response.response))
            }

            // Update cache
            lastPrompt = prompt
            lastSelectedModels = selectedModels

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        } catch {
            viewState = .error(error.localizedDescription)

            // Haptic feedback for error
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

    // MARK: - Helpers

    func getModelName(_ modelId: String) -> String {
        availableModels.first { $0.id == modelId }?.name ?? modelId
    }

    func getModelColor(_ modelId: String) -> Color {
        switch modelId {
        case "gemini":
            return Color.green
        case "llama-70b":
            return Color.blue
        case "llama-8b":
            return Color.purple
        case "mixtral":
            return Color.orange
        case "deepseek":
            return Color.cyan
        default:
            return Color.gray
        }
    }

    var canSubmit: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedModels.isEmpty
    }

    // MARK: - Conversation History

    func saveConversation() {
        guard let modelContext = modelContext,
              !responses.isEmpty,
              !prompt.isEmpty else { return }

        let chatResponse = ChatResponse(
            responses: responses,
            totalLatencyMs: totalLatency
        )

        // Convert conversation history to saved format
        var savedMessages: [SavedConversationMessage] = []
        for (modelId, messages) in conversationHistory {
            for message in messages {
                savedMessages.append(SavedConversationMessage.from(message, modelId: modelId))
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

        let conversation = Conversation(
            prompt: prompt,
            totalLatency: totalLatency,
            responses: savedResponses,
            conversationHistory: savedMessages
        )
        modelContext.insert(conversation)

        do {
            try modelContext.save()
            print("✅ Conversation saved successfully with \(savedMessages.count) follow-up messages")
        } catch {
            print("❌ Failed to save conversation: \(error)")
        }
    }

    func loadConversation(_ conversation: Conversation) {
        self.prompt = conversation.prompt
        self.responses = conversation.responses.map { $0.toModelResponse() }
        self.totalLatency = conversation.totalLatency
        self.viewState = .success
        self.selectedTab = 0

        // Restore conversation history from saved messages
        var restoredHistory: [String: [Message]] = [:]
        for savedMessage in conversation.conversationHistory {
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
    }

    func startNewChat() {
        prompt = ""
        responses = []
        viewState = .idle
        selectedTab = 0
        conversationHistory = [:]

        // Clear cache
        lastPrompt = ""
        lastSelectedModels = []
    }

    // MARK: - Follow-up Messages

    func sendFollowUpMessage(to modelId: String, message: String) async {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // Create a temporary loading state for this model
        if let index = responses.firstIndex(where: { $0.model == modelId }) {
            // Update existing response to show loading
            let updatedResponse = responses[index]
            responses[index] = ModelResponse(
                model: modelId,
                response: updatedResponse.response,
                tokens: updatedResponse.tokens,
                latencyMs: updatedResponse.latencyMs,
                error: nil
            )
        }

        do {
            let newResponse: ModelResponse

            // Check if this is an on-device model
            if onDeviceModelIds.contains(modelId) {
                // Use MLX service for on-device model
                let history = conversationHistory[modelId] ?? []
                newResponse = try await mlxService.generate(
                    prompt: message,
                    temperature: 0.7,
                    maxTokens: 512,
                    conversationHistory: history
                )
            } else {
                // Use API service for cloud models
                var historyForModel: [String: [Message]] = [:]
                if let history = conversationHistory[modelId] {
                    historyForModel[modelId] = history
                }

                let request = ChatRequest(
                    prompt: message,
                    models: [modelId],
                    conversationHistory: historyForModel.isEmpty ? nil : historyForModel
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
            if conversationHistory[modelId] == nil {
                conversationHistory[modelId] = []
            }

            conversationHistory[modelId]?.append(Message(role: "user", content: message))

            if newResponse.error == nil {
                conversationHistory[modelId]?.append(Message(role: "assistant", content: newResponse.response))
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        } catch {
            // Handle error
            if let index = responses.firstIndex(where: { $0.model == modelId }) {
                responses[index] = ModelResponse(
                    model: modelId,
                    response: responses[index].response,
                    tokens: nil,
                    latencyMs: 0,
                    error: error.localizedDescription
                )
            }

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    func getConversationMessages(for modelId: String) -> [Message] {
        return conversationHistory[modelId] ?? []
    }
}
