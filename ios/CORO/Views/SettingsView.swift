import SwiftUI

struct SettingsView: View {
    @ObservedObject var apiService: APIService
    @Environment(\.dismiss) var dismiss
    @State private var editedURL: String = ""
    @State private var editedToken: String = ""
    @State private var showingHealthStatus = false
    @State private var isHealthy = false
    @State private var isCheckingHealth = false

    var body: View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Backend URL", text: $editedURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)

                        if isCheckingHealth {
                            ProgressView()
                        } else if showingHealthStatus {
                            Image(systemName: isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isHealthy ? .green : .red)
                        }
                    }

                    SecureField("API Token (optional)", text: $editedToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(editedURL.isEmpty)
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("The backend API endpoint URL. Default: https://coro-production.up.railway.app")
                }

                Section {
                    Button("Reset to Default") {
                        editedURL = "https://coro-production.up.railway.app"
                        editedToken = ""
                        apiService.baseURL = editedURL
                        apiService.apiToken = editedToken
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("CORO - Multi-LLM Chat Comparison\nCompare responses from different AI models side-by-side.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .onAppear {
                editedURL = apiService.baseURL
                editedToken = apiService.apiToken
            }
        }
    }

    private func saveSettings() {
        apiService.baseURL = editedURL
        apiService.apiToken = editedToken
    }

    private func testConnection() {
        isCheckingHealth = true
        showingHealthStatus = false

        // Save URL and token first
        apiService.baseURL = editedURL
        apiService.apiToken = editedToken

        Task {
            do {
                isHealthy = try await apiService.checkHealth()
                showingHealthStatus = true

                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(isHealthy ? .success : .error)

            } catch {
                isHealthy = false
                showingHealthStatus = true

                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }

            isCheckingHealth = false

            // Hide status after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showingHealthStatus = false
            }
        }
    }
}
