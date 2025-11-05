import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingSettings = false
    @State private var showingParameters = false
    @State private var showingSidebar = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            NavigationStack {
                Group {
                    if viewModel.viewState == .success && !viewModel.responses.isEmpty {
                        ResultsView(
                            viewModel: viewModel,
                            onClose: {
                                viewModel.returnToPrompt()
                            },
                            onOpenSettings: {
                                showingSettings = true
                            }
                        )
                    } else {
                        InputView(
                            viewModel: viewModel,
                            onShowParameters: { showingParameters = true },
                            onShowSettings: { showingSettings = true }
                        )
                        .allowsHitTesting(viewModel.viewState != .loading)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(.hidden, for: .navigationBar)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    showingSidebar.toggle()
                                } label: {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.title3)
                                        .foregroundColor(AppTheme.Colors.accent)
                                }
                            }

                            ToolbarItem(placement: .principal) {
                                if !showingSidebar {
                                    Text("CORO")
                                        .font(AppTheme.Typography.title)
                                        .foregroundStyle(AppTheme.Gradients.accent)
                                }
                            }

                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    showingSettings = true
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .font(.title3)
                                        .foregroundColor(AppTheme.Colors.accent)
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(apiService: viewModel.apiService)
            }
            .sheet(isPresented: $showingParameters) {
                ModelParametersSheet(viewModel: viewModel)
            }
            .overlay {
                if showingSidebar && (viewModel.viewState != .success || viewModel.responses.isEmpty) {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showingSidebar = false
                            }
                        }

                    HStack(spacing: 0) {
                        SidebarView(viewModel: viewModel, isPresented: $showingSidebar)
                            .frame(width: min(UIScreen.main.bounds.width * 0.85, 400))
                            .transition(.move(edge: .leading))

                        Spacer()
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showingSidebar)
        }
        .overlay {
            if viewModel.viewState == .loading {
                LoadingSkeletonView(modelCount: viewModel.selectedModels.count)
                    .transition(.opacity)
            }
        }
        .task {
            await viewModel.loadAvailableModels()
        }
        .onAppear {
            viewModel.modelContext = modelContext
        }
    }
}

struct InputView: View {
    @ObservedObject var viewModel: ChatViewModel
    let onShowParameters: () -> Void
    let onShowSettings: () -> Void
    @FocusState private var isPromptFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if let error = viewModel.globalError {
                let action = primaryAction(for: error)
                Group {
                    GlobalErrorBanner(
                        error: error,
                        actionTitle: action?.title,
                        action: action?.handler,
                        onDismiss: { withAnimation { viewModel.globalError = nil } }
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }

            ScrollView {
                VStack(spacing: 40) {
                    // Spacer for top
                    Spacer()
                        .frame(height: 20)

                    // Prompt Input
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What would you like to ask?")
                            .font(AppTheme.Typography.hero)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        ZStack(alignment: .topLeading) {
                            // Placeholder
                            if viewModel.prompt.isEmpty && !isPromptFocused {
                                Text("Try asking about anything...")
                                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
                                    .padding(.horizontal, 6)
                                    .padding(.top, 12)
                            }

                            // Text Editor
                            TextEditor(text: $viewModel.prompt)
                                .focused($isPromptFocused)
                                .frame(minHeight: 140)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppTheme.Colors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    isPromptFocused ? AppTheme.Colors.accent.opacity(0.4) : AppTheme.Colors.outline.opacity(0.6),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
                    }
                    .padding(.horizontal, 24)

                    // Model Selection
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Select Models")
                                .font(AppTheme.Typography.title)
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Spacer()

                            Text("\(viewModel.selectedModels.count) selected")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.horizontal, 24)

                        ModelSelectorView(viewModel: viewModel)

                        Button {
                            onShowParameters()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.body.weight(.semibold))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Response style")
                                        .font(AppTheme.Typography.body)
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    Text("Adjust temperature, max tokens, and more.")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(AppTheme.Colors.outline.opacity(0.7))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppTheme.Colors.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(AppTheme.Colors.outline.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)
                        .buttonStyle(.plain)

                        if !viewModel.apiService.hasPremiumAccess {
                            UpsellCard(
                                title: "Need more headroom?",
                                message: "Sign in with Apple to unlock higher daily request limits and priority routing on cloud models.",
                                icon: "applelogo",
                                actionTitle: "Increase limits",
                                action: onShowSettings
                            )
                            .padding(.horizontal, 24)
                        }

                        if !viewModel.apiService.modelAPIKeys.hasAnyKeys {
                            UpsellCard(
                                title: "Bring your own keys",
                                message: "Connect your own Gemini, Groq, or DeepSeek keys to use your quotas and unlock premium models.",
                                icon: "key.fill",
                                actionTitle: "Add keys",
                                action: onShowSettings
                            )
                            .padding(.horizontal, 24)
                        }
                    }

                    // Error Message
                    if case .error(let message) = viewModel.viewState {
                        HStack(spacing: 14) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundColor(AppTheme.Colors.warning)

                            Text(message)
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Spacer()
                        }
                        .padding(20)
                        .background(AppTheme.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(AppTheme.Colors.warning.opacity(0.35), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                    }

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.bottom, 120)
            }

            // Ask Button (Fixed at bottom)
            VStack(spacing: 0) {
                Button {
                    isPromptFocused = false
                    Task {
                        await viewModel.sendChatRequest()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if viewModel.viewState == .loading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.1)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.title3)
                            Text("Ask Multiple AIs")
                                .font(AppTheme.Typography.subtitle)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        ZStack {
                            if viewModel.canSubmit {
                                AppTheme.Gradients.accent
                            } else {
                                Color.gray.opacity(0.3)
                            }
                        }
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: viewModel.canSubmit ? AppTheme.Colors.accent.opacity(0.4) : Color.clear, radius: 14, x: 0, y: 7)
                }
                .disabled(!viewModel.canSubmit || viewModel.viewState == .loading)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 30)
                .background(AppTheme.Colors.surface.opacity(0.9))
            }
        }
    }

    private func primaryAction(for error: GlobalError) -> (title: String, handler: () -> Void)? {
        guard let code = error.code else { return nil }

        switch code {
        case "authentication_failed", "api_key_missing", "api_key_invalid", "unauthorized":
            return ("Open Settings", onShowSettings)
        default:
            return nil
        }
    }
}

private struct UpsellCard: View {
    let title: String
    let message: String
    let icon: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.Gradients.accent)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.Colors.surfaceElevated.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(AppTheme.Typography.subtitle)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(message)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(action: action) {
                HStack {
                    Spacer()
                    Text(actionTitle)
                        .font(AppTheme.Typography.caption.weight(.semibold))
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(AppTheme.Colors.surfaceElevated)
                .foregroundColor(AppTheme.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.Colors.accent.opacity(0.35), lineWidth: 1)
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppTheme.Colors.surface.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppTheme.Colors.outline.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    ContentView()
}
