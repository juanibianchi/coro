import Foundation
import SwiftData

@Model
final class Conversation {
    var id: UUID
    var prompt: String
    var timestamp: Date
    var totalLatency: Int
    var responses: [SavedModelResponse]
    var conversationHistory: [SavedConversationMessage]  // Store follow-up messages

    init(prompt: String, totalLatency: Int, responses: [SavedModelResponse], conversationHistory: [SavedConversationMessage] = []) {
        self.id = UUID()
        self.prompt = prompt
        self.timestamp = Date()
        self.totalLatency = totalLatency
        self.responses = responses
        self.conversationHistory = conversationHistory
    }

    // Convenience initializer from live chat response
    convenience init(from chatResponse: ChatResponse, prompt: String) {
        let savedResponses = chatResponse.responses.map { response in
            SavedModelResponse(
                model: response.model,
                response: response.response,
                tokens: response.tokens,
                latencyMs: response.latencyMs,
                error: response.error
            )
        }
        self.init(prompt: prompt, totalLatency: chatResponse.totalLatencyMs, responses: savedResponses, conversationHistory: [])
    }
}

@Model
final class SavedModelResponse {
    var model: String
    var response: String
    var tokens: Int?
    var latencyMs: Int
    var error: String?

    init(model: String, response: String, tokens: Int?, latencyMs: Int, error: String?) {
        self.model = model
        self.response = response
        self.tokens = tokens
        self.latencyMs = latencyMs
        self.error = error
    }

    var hasError: Bool {
        error != nil
    }

    var displayLatency: String {
        "\(latencyMs)ms"
    }

    var displayTokens: String {
        if let tokens = tokens {
            return "\(tokens) tokens"
        }
        return ""
    }
}

// Extension to convert SavedModelResponse back to ModelResponse for UI
extension SavedModelResponse {
    func toModelResponse() -> ModelResponse {
        return ModelResponse(
            model: model,
            response: response,
            tokens: tokens,
            latencyMs: latencyMs,
            error: error
        )
    }
}

// Model to store conversation messages (follow-ups) in per-model history
@Model
final class SavedConversationMessage {
    var modelId: String  // Which model this history is for
    var role: String     // "user" or "assistant"
    var content: String

    init(modelId: String, role: String, content: String) {
        self.modelId = modelId
        self.role = role
        self.content = content
    }
}

// Extension to convert between Message and SavedConversationMessage
extension SavedConversationMessage {
    func toMessage() -> Message {
        return Message(role: role, content: content)
    }

    static func from(_ message: Message, modelId: String) -> SavedConversationMessage {
        return SavedConversationMessage(modelId: modelId, role: message.role, content: message.content)
    }
}
