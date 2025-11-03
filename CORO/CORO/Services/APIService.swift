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
            // Don't use convertToSnakeCase since we have manual CodingKeys mappings
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            throw APIError.decodingError(error)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            // Debug: Print response data
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 API Response: \(responseString)")
            }

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
            // Don't use convertFromSnakeCase since we have manual CodingKeys mappings

            do {
                let chatResponse = try decoder.decode(ChatResponse.self, from: data)
                print("✅ Successfully decoded ChatResponse with \(chatResponse.responses.count) responses")
                return chatResponse
            } catch let decodingError {
                print("❌ Decoding error: \(decodingError)")
                if let decodingError = decodingError as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("❌ Missing key: \(key.stringValue) - \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("❌ Type mismatch for type \(type) - \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("❌ Value not found for type \(type) - \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("❌ Data corrupted - \(context.debugDescription)")
                    @unknown default:
                        print("❌ Unknown decoding error")
                    }
                }
                throw APIError.decodingError(decodingError)
            }

        } catch let error as APIError {
            throw error
        } catch {
            print("❌ Network error: \(error)")
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

            // Debug: Print response
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Models Response: \(responseString)")
            }

            let decoder = JSONDecoder()
            let response = try decoder.decode(ModelsResponse.self, from: data)
            print("✅ Successfully decoded \(response.models.count) models")
            return response.models
        } catch {
            print("❌ Models fetch error: \(error)")
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
