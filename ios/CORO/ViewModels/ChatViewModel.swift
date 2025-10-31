import Foundation
import SwiftUI

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

    let apiService: APIService

    init(apiService: APIService = APIService()) {
        self.apiService = apiService
        loadDefaultModels()
    }

    // MARK: - Load Available Models

    func loadAvailableModels() async {
        do {
            let models = try await apiService.fetchAvailableModels()
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
            ModelInfo(id: "mixtral", name: "Llama 4 Maverick", provider: "Groq", cost: "free")
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

        viewState = .loading
        responses = []
        selectedTab = 0

        do {
            let request = ChatRequest(
                prompt: prompt,
                models: Array(selectedModels)
            )

            let result = try await apiService.sendChatRequest(request)
            self.responses = result.responses
            self.totalLatency = result.totalLatencyMs
            self.viewState = .success

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
}
