import SwiftUI
import AuthenticationServices
import UIKit

enum AppleSignInManagerError: Error {
    case missingIdentityToken
    case missingPresentationAnchor
}

final class AppleSignInManager: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let anchor = scene.windows.first(where: { $0.isKeyWindow })
        else {
            return UIWindow()
        }
        return anchor
    }

    func signIn() async throws -> ASAuthorizationAppleIDCredential {
        if continuation != nil {
            throw NSError(domain: "com.coro.signin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign in already in progress. Please wait."])
        }

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: NSError(domain: "com.coro.signin", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unexpected authorization credential."]))
            continuation = nil
            return
        }

        continuation?.resume(returning: credential)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}


struct SettingsView: View {
    @ObservedObject var apiService: APIService
    @Environment(\.dismiss) private var dismiss

    @State private var editedURL: String = ""
    @State private var editedToken: String = ""
    @State private var editedConversationGuide: String = ""
    @State private var editedSearchDefault: Bool = false
    @State private var showingHealthStatus = false
    @State private var isHealthy = false
    @State private var isCheckingHealth = false
    @State private var isSigningIn = false
    @State private var appleErrorMessage: String?

    private let appleSignInManager = AppleSignInManager()

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                conversationDefaultsSection
                endpointSection
                byokSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .onAppear {
                editedURL = apiService.baseURL
                editedToken = apiService.apiToken
                editedConversationGuide = apiService.conversationGuide
                editedSearchDefault = apiService.searchEnabledByDefault
            }
            .alert("Sign in with Apple", isPresented: Binding(
                get: { appleErrorMessage != nil },
                set: { if !$0 { appleErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { appleErrorMessage = nil }
            } message: {
                Text(appleErrorMessage ?? "An unknown error occurred.")
            }
        }
    }

    // MARK: - Sections

    private var accountSection: some View {
        Section("Account") {
            if apiService.hasPremiumAccess {
                Label("Premium access active", systemImage: "checkmark.seal.fill")
                    .foregroundColor(.green)

                Text("You're signed in with Apple. CORO uses this to raise your daily conversation allowance—your personal details stay on-device.")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Button(role: .destructive) {
                    apiService.clearPremiumSession()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } else {
                Button {
                    Task { await startAppleSignIn() }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "applelogo")
                            .font(.title2)
                        Text(isSigningIn ? "Signing in..." : "Sign in with Apple")
                            .font(.headline)
                        Spacer()
                        if isSigningIn {
                            ProgressView()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.Colors.accent)
                .disabled(isSigningIn)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sign in to unlock higher daily limits and faster routing for cloud models.")
                    Text("We only use your Apple ID for verification; your name and email never leave your device.")
                }
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    private var endpointSection: some View {
        Section("Backend Configuration") {
            VStack(alignment: .leading, spacing: 8) {
                Text("API Endpoint")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                TextField("https://coro-production.up.railway.app", text: $editedURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                Text("CORO iOS will send all requests to this URL.")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Backend Token (Optional)")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                SecureField("Bearer token", text: $editedToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Text("Set this if your CORO backend requires an Authorization header.")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Button {
                Task { await testConnection() }
            } label: {
                HStack {
                    if isCheckingHealth {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Image(systemName: "network")
                    }

                    Text(isCheckingHealth ? "Checking..." : "Test Connection")
                        .fontWeight(.semibold)

                    Spacer()

                    if showingHealthStatus {
                        Image(systemName: isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isHealthy ? .green : .red)
                    }
                }
            }
            .disabled(isCheckingHealth)
        }
    }

    private var conversationDefaultsSection: some View {
        Section("Conversation Defaults") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Custom Instructions")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                ZStack(alignment: .topLeading) {
                    if editedConversationGuide.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("e.g., \"Always respond in a concise, professional tone\" or \"Provide code examples in Swift when discussing iOS development\"")
                            .font(.body)
                            .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                    }

                    TextEditor(text: $editedConversationGuide)
                        .frame(minHeight: 140)
                        .padding(12)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                }
                .background(AppTheme.Colors.surface.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.Colors.outline.opacity(0.3), lineWidth: 0.8)
                )

                Text("Add global instructions that all AI models will follow. This helps personalize responses to your preferences.")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Toggle(isOn: $editedSearchDefault) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-run web search")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("When enabled, CORO fetches web context for each new prompt before asking the models.")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .tint(AppTheme.Colors.accent)

            Button(role: .none) {
                withAnimation {
                    editedConversationGuide = ""
                }
            } label: {
                Label("Clear Instructions", systemImage: "xmark.circle")
                    .font(.caption)
            }
            .foregroundColor(AppTheme.Colors.textSecondary)
            .padding(.top, 4)
            .disabled(editedConversationGuide.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var byokSection: some View {
        Section("Bring Your Own Keys") {
            NavigationLink {
                BYOKSettingsView(apiService: apiService)
            } label: {
                HStack {
                    Image(systemName: "key.fill")
                    Text("Store model provider keys")
                    Spacer()
                    if apiService.modelAPIKeys.hasAnyKeys {
                        Text("Configured")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            Text("Optional: store your own provider keys securely in Keychain. These will override the default CORO keys when available.")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)

            Text("Keys stay encrypted on your device and are used only when you run a request. Remove them anytime with Clear.")
                .font(.caption2)
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.9))
        }
    }

    private var aboutSection: some View {
        Section("About CORO") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ask once, hear from many.")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("CORO gathers multiple AI perspectives for every question so you can explore ideas, trade-offs, and blind spots with ease.")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Multiple cloud + on-device models in one tap", systemImage: "sparkles")
                    Label("Apple Sign In boosts the daily rate limit", systemImage: "bolt.fill")
                    Label("Bring your own keys to use your model quotas securely", systemImage: "key.fill")
                }
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)

                Link(destination: URL(string: "https://github.com")!) {
                    Label("Project repository", systemImage: "arrow.up.right.circle")
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Actions

    @MainActor
    private func startAppleSignIn() async {
        guard !isSigningIn else { return }
        isSigningIn = true

        defer { isSigningIn = false }

        do {
            let credential = try await appleSignInManager.signIn()
            guard let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                throw AppleSignInManagerError.missingIdentityToken
            }

            _ = try await apiService.registerPremiumSession(identityToken: tokenString, nonce: credential.state)
        } catch {
            appleErrorMessage = error.localizedDescription
        }
    }

    private func saveSettings() {
        apiService.baseURL = editedURL
        apiService.apiToken = editedToken
        apiService.updateConversationGuide(editedConversationGuide)
        apiService.updateSearchDefault(editedSearchDefault)
    }

    private func testConnection() async {
        showingHealthStatus = false
        isCheckingHealth = true

        do {
            apiService.baseURL = editedURL
            apiService.apiToken = editedToken
            let healthy = try await apiService.checkHealth()
            await MainActor.run {
                isHealthy = healthy
                showingHealthStatus = true
            }
        } catch {
            await MainActor.run {
                isHealthy = false
                showingHealthStatus = true
            }
        }

        await MainActor.run {
            isCheckingHealth = false
        }
    }
}

private struct BYOKSettingsView: View {
    @ObservedObject var apiService: APIService
    @Environment(\.dismiss) private var dismiss

    @State private var keys: ModelAPIKeys
    @State private var hasChanges = false
    @State private var showClearedConfirmation = false

    init(apiService: APIService) {
        self.apiService = apiService
        _keys = State(initialValue: apiService.modelAPIKeys)
    }

    var body: some View {
        Form {
            Section("Google Gemini") {
                SecureField("Gemini API Key", text: $keys.gemini)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Groq (Llama / Mixtral)") {
                SecureField("Groq API Key", text: $keys.groq)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("DeepSeek") {
                SecureField("DeepSeek API Key", text: $keys.deepseek)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            if showClearedConfirmation {
                Section {
                    Label("Removed stored keys", systemImage: "checkmark.shield")
                        .foregroundColor(.green)
                }
            }
        }
        .navigationTitle("Your API Keys")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Clear") {
                    withAnimation {
                        keys = ModelAPIKeys()
                        showClearedConfirmation = true
                        hasChanges = true
                    }
                }
                .disabled(!keys.hasAnyKeys && apiService.modelAPIKeys.hasAnyKeys == false)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    applyChanges()
                }
                .disabled(!hasChanges)
            }
        }
        .onChange(of: keys) { _, newValue in
            hasChanges = newValue != apiService.modelAPIKeys
        }
    }

    private func applyChanges() {
        apiService.modelAPIKeys = keys
        dismiss()
    }
}
