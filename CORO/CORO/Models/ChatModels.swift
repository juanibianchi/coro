import Foundation

// MARK: - Message Models

struct Message: Codable, Identifiable, Equatable {
    var id = UUID()
    let role: String  // "user" or "assistant"
    let content: String

    var isUser: Bool {
        role == "user"
    }
}

extension Message {
    static let pendingAssistantPlaceholder = "__pending_response_placeholder__"

    var isPendingAssistant: Bool {
        !isUser && content == Message.pendingAssistantPlaceholder
    }
}

// MARK: - Request Models

struct ChatRequest: Codable {
    let prompt: String
    let models: [String]
    let temperature: Double
    let maxTokens: Int
    let topP: Double?
    let conversationHistory: [String: [Message]]?
    let apiOverrides: [String: String]?

    enum CodingKeys: String, CodingKey {
        case prompt, models, temperature
        case maxTokens = "max_tokens"
        case topP = "top_p"
        case conversationHistory = "conversation_history"
        case apiOverrides = "api_overrides"
    }

    init(
        prompt: String,
        models: [String],
        temperature: Double = 0.7,
        maxTokens: Int = 2000,
        topP: Double? = nil,
        conversationHistory: [String: [Message]]? = nil,
        apiOverrides: [String: String]? = nil
    ) {
        self.prompt = prompt
        self.models = models
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.conversationHistory = conversationHistory
        self.apiOverrides = apiOverrides
    }
}

// MARK: - Response Models

struct ChatResponse: Codable {
    let responses: [ModelResponse]
    let totalLatencyMs: Int

    enum CodingKeys: String, CodingKey {
        case responses
        case totalLatencyMs = "total_latency_ms"
    }
}

struct ModelResponse: Codable, Identifiable, Equatable {
    var id: String { model }
    let model: String
    let response: String
    let tokens: Int?
    let latencyMs: Int
    let error: String?
    let errorCode: String?

    enum CodingKeys: String, CodingKey {
        case model, response, tokens, error
        case latencyMs = "latency_ms"
        case errorCode = "error_code"
    }

    var hasError: Bool {
        error != nil
    }

    var userFriendlyError: String {
        guard let errorCode = errorCode else {
            return error ?? "Unknown error"
        }

        return ErrorCodeHelper.getUserFriendlyMessage(for: errorCode, originalMessage: error ?? "")
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

// MARK: - Model Info

struct ModelInfo: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let provider: String
    let cost: String

    var displayName: String {
        name
    }

    var isPremium: Bool {
        cost != "free"
    }
}

struct ModelsResponse: Codable {
    let models: [ModelInfo]
}

// MARK: - Health Check

struct HealthResponse: Codable {
    let status: String
    let timestamp: String
}

struct AppleSignInResponse: Codable {
    let sessionToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case sessionToken = "session_token"
        case expiresIn = "expires_in"
    }
}
