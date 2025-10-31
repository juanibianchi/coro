import Foundation

// MARK: - Request Models

struct ChatRequest: Codable {
    let prompt: String
    let models: [String]
    let temperature: Double
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case prompt, models, temperature
        case maxTokens = "max_tokens"
    }

    init(prompt: String, models: [String], temperature: Double = 0.7, maxTokens: Int = 512) {
        self.prompt = prompt
        self.models = models
        self.temperature = temperature
        self.maxTokens = maxTokens
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

struct ModelResponse: Codable, Identifiable {
    var id: String { model }
    let model: String
    let response: String
    let tokens: Int?
    let latencyMs: Int
    let error: String?

    enum CodingKeys: String, CodingKey {
        case model, response, tokens, error
        case latencyMs = "latency_ms"
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

// MARK: - Model Info

struct ModelInfo: Codable, Identifiable {
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
