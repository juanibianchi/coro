import SwiftUI

struct SettingsView: View {
    @ObservedObject var apiService: APIService
    @Environment(\.dismiss) var dismiss
    @State private var editedURL: String = ""
    @State private var showingHealthStatus = false
    @State private var isHealthy = false
    @State private var isCheckingHealth = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.99, green: 0.96, blue: 0.92)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // API Configuration Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("API Configuration")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Backend URL")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                                HStack {
                                    TextField("http://localhost:8000", text: $editedURL)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .keyboardType(.URL)
                                        .font(.system(size: 15))
                                        .padding(12)
                                        .background(Color.white.opacity(0.5))
                                        .cornerRadius(10)

                                    if isCheckingHealth {
                                        ProgressView()
                                            .scaleEffect(0.9)
                                            .frame(width: 44)
                                    } else if showingHealthStatus {
                                        Image(systemName: isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(isHealthy ? .green : .red)
                                            .font(.title3)
                                            .frame(width: 44)
                                    }
                                }

                                Text("The backend API endpoint URL")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 12) {
                                Button {
                                    testConnection()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "network")
                                        Text("Test Connection")
                                    }
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: editedURL.isEmpty ? [Color.gray.opacity(0.3)] : [Color(red: 0.95, green: 0.5, blue: 0.2), Color(red: 0.85, green: 0.4, blue: 0.3)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .disabled(editedURL.isEmpty)

                                Button {
                                    editedURL = "http://localhost:8000"
                                    apiService.baseURL = editedURL
                                } label: {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.2))
                                        .frame(width: 44, height: 44)
                                        .background(Color.white.opacity(0.5))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

                        // About Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.2))
                                    Text("Version")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("1.0.0")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Divider()

                                Link(destination: URL(string: "https://github.com")!) {
                                    HStack {
                                        Image(systemName: "link.circle.fill")
                                            .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.2))
                                        Text("GitHub")
                                            .font(.subheadline)
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption)
                                    }
                                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                                }
                            }

                            Text("CORO - Multi-LLM Chat Comparison\nCompare responses from different AI models side-by-side.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        saveSettings()
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.2))
                    }
                }
            }
            .onAppear {
                editedURL = apiService.baseURL
            }
        }
    }

    private func saveSettings() {
        apiService.baseURL = editedURL
    }

    private func testConnection() {
        isCheckingHealth = true
        showingHealthStatus = false

        // Save URL first
        apiService.baseURL = editedURL

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
