import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingSettings = false

    var body: View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.viewState == .success && !viewModel.responses.isEmpty {
                    // Results View
                    ResultsView(viewModel: viewModel)
                } else {
                    // Input View
                    InputView(viewModel: viewModel)
                }
            }
            .navigationTitle("CORO")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(apiService: viewModel.apiService)
            }
        }
        .task {
            await viewModel.loadAvailableModels()
        }
    }
}

struct InputView: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: View {
        ScrollView {
            VStack(spacing: 24) {
                // Prompt Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's your question?")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    ZStack(alignment: .topLeading) {
                        if viewModel.prompt.isEmpty {
                            Text("Ask anything...")
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }

                        TextEditor(text: $viewModel.prompt)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)

                // Model Selection
                ModelSelectorView(viewModel: viewModel)

                // Compare Button
                Button {
                    Task {
                        await viewModel.sendChatRequest()
                    }
                } label: {
                    HStack {
                        if viewModel.viewState == .loading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Compare Models")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(viewModel.canSubmit ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .disabled(!viewModel.canSubmit || viewModel.viewState == .loading)
                .padding(.horizontal)

                // Error Message
                if case .error(let message) = viewModel.viewState {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
        }
    }
}

#Preview {
    ContentView()
}
