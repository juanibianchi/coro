import Foundation

import Security

private enum KeychainError: Error {
    case unhandledError(status: OSStatus)
}

private enum KeychainService {
    private static let service = "com.coro.securestore"

    static func set(_ value: String?, for key: String) throws {
        guard let value else {
            try delete(key)
            return
        }

        let encoded = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: encoded,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)

        if status == errSecSuccess {
            let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: updateStatus)
            }
        } else if status == errSecItemNotFound {
            var newItem = query
            newItem.merge(attributes) { $1 }
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: addStatus)
            }
        } else if status != errSecItemNotFound {
            throw KeychainError.unhandledError(status: status)
        }
    }

    static func string(for key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }

        guard let data = item as? Data, let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    static func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(message: String, code: String?, statusCode: Int?, retryAfter: Int?)

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
        case .serverError(let message, _, _, _):
            return message
        }
    }
}

struct ModelAPIKeys: Codable, Equatable {
    var gemini: String = ""
    var groq: String = ""
    var deepseek: String = ""

    var hasAnyKeys: Bool {
        !gemini.isEmpty || !groq.isEmpty || !deepseek.isEmpty
    }

    var overridesDictionary: [String: String] {
        var overrides: [String: String] = [:]

        if !gemini.isEmpty {
            overrides["gemini"] = gemini
        }

        if !groq.isEmpty {
            overrides["llama-70b"] = groq
            overrides["llama-8b"] = groq
            overrides["mixtral"] = groq
        }

        if !deepseek.isEmpty {
            overrides["deepseek"] = deepseek
        }

        return overrides
    }

    func storedString() throws -> String? {
        guard hasAnyKeys else { return nil }
        let data = try JSONEncoder().encode(self)
        return String(data: data, encoding: .utf8)
    }

    static func fromStoredString(_ stored: String?) -> ModelAPIKeys {
        guard
            let stored,
            let data = stored.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(ModelAPIKeys.self, from: data)
        else {
            return ModelAPIKeys()
        }
        return decoded
    }
}

private struct AppleSignInPayload: Codable {
    let identityToken: String
    let nonce: String?

    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case nonce
    }
}

private struct ServerErrorDetail: Codable {
    let message: String?
    let errorCode: String?
    let retryAfter: Int?

    enum CodingKeys: String, CodingKey {
        case message
        case errorCode = "error_code"
        case retryAfter = "retry_after"
    }
}

private struct ServerErrorEnvelope: Codable {
    let detail: ServerErrorDetail
}

private struct ServerErrorStringEnvelope: Codable {
    let detail: String
}

class APIService: ObservableObject {
    private enum KeychainKeys {
        static let apiToken = "coro.apiToken"
        static let sessionToken = "coro.sessionToken"
        static let modelAPIKeys = "coro.modelApiKeys"
        static let deviceIdentifier = "coro.deviceIdentifier"
    }

    private enum UserDefaultsKeys {
        static let conversationGuide = "coro.conversationGuide"
        static let searchEnabled = "coro.searchEnabledByDefault"
    }

    @Published var baseURL: String {
        didSet {
            UserDefaults.standard.set(baseURL, forKey: "apiEndpoint")
        }
    }

    @Published var apiToken: String {
        didSet {
            try? KeychainService.set(apiToken.isEmpty ? nil : apiToken, for: KeychainKeys.apiToken)
        }
    }

    @Published private(set) var sessionToken: String? {
        didSet {
            try? KeychainService.set(sessionToken, for: KeychainKeys.sessionToken)
            hasPremiumAccess = sessionToken?.isEmpty == false
        }
    }

    @Published var modelAPIKeys: ModelAPIKeys {
        didSet {
            if let stored = try? modelAPIKeys.storedString() {
                try? KeychainService.set(stored, for: KeychainKeys.modelAPIKeys)
            } else {
                try? KeychainService.set(nil, for: KeychainKeys.modelAPIKeys)
            }
        }
    }

    @Published var conversationGuide: String {
        didSet {
            UserDefaults.standard.set(conversationGuide, forKey: UserDefaultsKeys.conversationGuide)
        }
    }

    @Published var searchEnabledByDefault: Bool {
        didSet {
            UserDefaults.standard.set(searchEnabledByDefault, forKey: UserDefaultsKeys.searchEnabled)
        }
    }

    @Published private(set) var hasPremiumAccess: Bool

    let deviceIdentifier: String

    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()

    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()

    init() {
        baseURL = UserDefaults.standard.string(forKey: "apiEndpoint") ?? "https://coro-production.up.railway.app"
        apiToken = (try? KeychainService.string(for: KeychainKeys.apiToken)) ?? ""

        let storedModelKeys: String?
        do {
            storedModelKeys = try KeychainService.string(for: KeychainKeys.modelAPIKeys)
        } catch {
            storedModelKeys = nil
        }
        modelAPIKeys = ModelAPIKeys.fromStoredString(storedModelKeys)

        let storedDeviceId: String?
        do {
            storedDeviceId = try KeychainService.string(for: KeychainKeys.deviceIdentifier)
        } catch {
            storedDeviceId = nil
        }

        if let existingDeviceId = storedDeviceId, !existingDeviceId.isEmpty {
            deviceIdentifier = existingDeviceId
        } else {
            let newIdentifier = UUID().uuidString
            deviceIdentifier = newIdentifier
            try? KeychainService.set(newIdentifier, for: KeychainKeys.deviceIdentifier)
        }

        conversationGuide = UserDefaults.standard.string(forKey: UserDefaultsKeys.conversationGuide) ?? ""
        searchEnabledByDefault = UserDefaults.standard.object(forKey: UserDefaultsKeys.searchEnabled) as? Bool ?? false

        hasPremiumAccess = false

        let storedSession: String?
        do {
            storedSession = try KeychainService.string(for: KeychainKeys.sessionToken)
        } catch {
            storedSession = nil
        }
        sessionToken = storedSession
    }

    // MARK: - Public Mutations

    func clearPremiumSession() {
        sessionToken = nil
    }

    // MARK: - Chat Request

    func sendChatRequest(_ request: ChatRequest) async throws -> ChatResponse {
        guard let url = URL(string: "\(baseURL)/chat") else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuthHeaders(to: &urlRequest)

        let overrides = request.apiOverrides ?? {
            let dict = modelAPIKeys.overridesDictionary
            return dict.isEmpty ? nil : dict
        }()

        let outboundRequest = ChatRequest(
            prompt: request.prompt,
            models: request.models,
            temperature: request.temperature,
            maxTokens: request.maxTokens,
            topP: request.topP,
            conversationHistory: request.conversationHistory,
            apiOverrides: overrides,
            conversationGuide: request.conversationGuide,
            searchContext: request.searchContext
        )

        do {
            urlRequest.httpBody = try jsonEncoder.encode(outboundRequest)
        } catch {
            throw APIError.decodingError(error)
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        return try decodeChatResponse(data: data, response: response)
    }

    // MARK: - Fetch Models

    func fetchAvailableModels() async throws -> [ModelInfo] {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        applyAuthHeaders(to: &urlRequest)

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw APIError.invalidResponse
            }
            let decoded = try jsonDecoder.decode(ModelsResponse.self, from: data)
            return decoded.models
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Health Check

    func checkHealth() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        applyAuthHeaders(to: &urlRequest)

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw APIError.invalidResponse
            }

            let health = try jsonDecoder.decode(HealthResponse.self, from: data)
            return health.status == "ok"
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Premium Sessions

    func registerPremiumSession(identityToken: String, nonce: String?) async throws -> AppleSignInResponse {
        guard let url = URL(string: "\(baseURL)/auth/apple") else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuthHeaders(to: &urlRequest)

        let payload = AppleSignInPayload(identityToken: identityToken, nonce: nonce)
        urlRequest.httpBody = try jsonEncoder.encode(payload)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let envelope = try? jsonDecoder.decode(ServerErrorEnvelope.self, from: data) {
                let message = envelope.detail.message ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                throw APIError.serverError(
                    message: message,
                    code: envelope.detail.errorCode,
                    statusCode: httpResponse.statusCode,
                    retryAfter: envelope.detail.retryAfter
                )
            }

            if let stringEnvelope = try? jsonDecoder.decode(ServerErrorStringEnvelope.self, from: data) {
                throw APIError.serverError(
                    message: stringEnvelope.detail,
                    code: nil,
                    statusCode: httpResponse.statusCode,
                    retryAfter: nil
                )
            }

            throw APIError.serverError(
                message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
                code: nil,
                statusCode: httpResponse.statusCode,
                retryAfter: nil
            )
        }

        let signedIn = try jsonDecoder.decode(AppleSignInResponse.self, from: data)

        await MainActor.run {
            self.sessionToken = signedIn.sessionToken
        }

        return signedIn
    }

    // MARK: - Search

    struct SearchResult: Codable, Identifiable, Equatable {
        let id: UUID
        let title: String
        let snippet: String
        let url: String

        init(id: UUID = UUID(), title: String, snippet: String, url: String) {
            self.id = id
            self.title = title
            self.snippet = snippet
            self.url = url
        }

        private enum CodingKeys: String, CodingKey {
            case title, snippet, url
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let title = try container.decode(String.self, forKey: .title)
            let snippet = try container.decode(String.self, forKey: .snippet)
            let url = try container.decode(String.self, forKey: .url)
            self.init(title: title, snippet: snippet, url: url)
        }
    }

    private struct SearchResponse: Codable {
        let query: String
        let results: [SearchResult]
    }

    @MainActor
    func updateConversationGuide(_ guide: String) {
        conversationGuide = guide
    }

    @MainActor
    func updateSearchDefault(_ enabled: Bool) {
        searchEnabledByDefault = enabled
    }

    func performSearch(query: String) async throws -> [SearchResult] {
        guard let url = URL(string: "\(baseURL)/search"), !query.isEmpty else {
            return []
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "q", value: query)]

        guard let finalURL = components?.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: finalURL)
        applyAuthHeaders(to: &urlRequest)

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                if let envelope = try? jsonDecoder.decode(ServerErrorEnvelope.self, from: data) {
                    let message = envelope.detail.message ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                    throw APIError.serverError(
                        message: message,
                        code: envelope.detail.errorCode,
                        statusCode: httpResponse.statusCode,
                        retryAfter: envelope.detail.retryAfter
                    )
                }

                throw APIError.serverError(
                    message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
                    code: nil,
                    statusCode: httpResponse.statusCode,
                    retryAfter: nil
                )
            }

            let searchResponse = try jsonDecoder.decode(SearchResponse.self, from: data)
            return searchResponse.results
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Helpers

    private func decodeChatResponse(data: Data, response: URLResponse) throws -> ChatResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let envelope = try? jsonDecoder.decode(ServerErrorEnvelope.self, from: data) {
                let message = envelope.detail.message ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                throw APIError.serverError(
                    message: message,
                    code: envelope.detail.errorCode,
                    statusCode: httpResponse.statusCode,
                    retryAfter: envelope.detail.retryAfter
                )
            }

            if let stringEnvelope = try? jsonDecoder.decode(ServerErrorStringEnvelope.self, from: data) {
                throw APIError.serverError(
                    message: stringEnvelope.detail,
                    code: nil,
                    statusCode: httpResponse.statusCode,
                    retryAfter: nil
                )
            }

            throw APIError.serverError(
                message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
                code: nil,
                statusCode: httpResponse.statusCode,
                retryAfter: nil
            )
        }

        do {
            let chatResponse = try jsonDecoder.decode(ChatResponse.self, from: data)
            return chatResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func applyAuthHeaders(to request: inout URLRequest) {
        if !apiToken.isEmpty {
            request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        }

        request.setValue(deviceIdentifier, forHTTPHeaderField: "X-CORO-Device")

        if let sessionToken, !sessionToken.isEmpty {
            request.setValue(sessionToken, forHTTPHeaderField: "X-CORO-Session")
        }
    }
}
