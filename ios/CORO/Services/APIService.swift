import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL. Please check settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingError:
            return "Failed to parse server response."
        case .serverError(let message):
            return message
        }
    }
}

@MainActor
class APIService: ObservableObject {
    @Published var baseURL: String {
        didSet {
            UserDefaults.standard.set(baseURL, forKey: "apiEndpoint")
        }
    }

    init() {
        self.baseURL = UserDefaults.standard.string(forKey: "apiEndpoint") ?? "http://localhost:8000"
    }

    // MARK: - Chat Request

    func sendChatRequest(_ request: ChatRequest) async throws -> ChatResponse {
        guard let url = URL(string: "\(baseURL)/chat") else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            throw APIError.decodingError(error)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                // Try to decode error message
                if let errorDict = try? JSONDecoder().decode([String: String].self, from: data),
                   let detail = errorDict["detail"] {
                    throw APIError.serverError(detail)
                }
                throw APIError.serverError("Server returned status code \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(ChatResponse.self, from: data)

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Fetch Models

    func fetchAvailableModels() async throws -> [ModelInfo] {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw APIError.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(ModelsResponse.self, from: data)
            return response.models
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Health Check

    func checkHealth() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else {
            throw APIError.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(HealthResponse.self, from: data)
            return response.status == "ok"
        } catch {
            throw APIError.networkError(error)
        }
    }
}
