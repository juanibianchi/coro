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
                                    Text("Coro")
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

    private var conversationGuideText: String? {
        let raw = viewModel.apiService.conversationGuide.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? nil : raw
    }

    private var guideSummary: String? {
        guard let guide = conversationGuideText else { return nil }
        let firstLine = guide.components(separatedBy: .newlines).first ?? guide
        if firstLine.count > 80 {
            let trimmed = firstLine.prefix(80)
            return trimmed.trimmingCharacters(in: .whitespacesAndNewlines) + "…"
        }
        return firstLine
    }

    private var shouldShowContextChips: Bool {
        conversationGuideText != nil || viewModel.isSearchEnabled
    }

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
                VStack(spacing: 36) {
                    Spacer()
                        .frame(height: 4)

                    ZStack {
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .fill(AppTheme.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 36, style: .continuous)
                                    .stroke(AppTheme.Colors.outline.opacity(0.3), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 16)
                        Image("CoroLogo")
                            .resizable()
                            .scaledToFit()
                            .padding(16)
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                    .padding(.horizontal, 24)

                    // Prompt Input
                    VStack(alignment: .leading, spacing: 20) {
                        Text("What would you like to ask?")
                            .font(AppTheme.Typography.hero)
                            .foregroundColor(AppTheme.Colors.textPrimary.opacity(0.96))

                        ZStack(alignment: .topLeading) {
                            if viewModel.prompt.isEmpty && !isPromptFocused {
                                Text("Try asking about anything…")
                                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.85))
                                    .padding(.horizontal, 8)
                                    .padding(.top, 12)
                            }

                            TextEditor(text: $viewModel.prompt)
                                .focused($isPromptFocused)
                                .frame(minHeight: 150)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .background(Color.clear)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(AppTheme.Colors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(
                                    isPromptFocused ? AppTheme.Colors.accent.opacity(0.6) : AppTheme.Colors.outline.opacity(0.65),
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(AppTheme.Colors.surfaceElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(AppTheme.Colors.outline.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.22), radius: 22, x: 0, y: 12)
                    .padding(.horizontal, 18)

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

                        if shouldShowContextChips {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    if let summary = guideSummary {
                                        ContextChip(
                                            icon: "bookmark.fill",
                                            title: "Instructions active",
                                            subtitle: summary
                                        )
                                    }

                                    if viewModel.isSearchEnabled {
                                        ContextChip(
                                            icon: viewModel.isSearching ? "hourglass" : "globe",
                                            title: viewModel.isSearching ? "Gathering context…" : "Web search on",
                                            subtitle: viewModel.isSearching ? "Fetching latest sources" : "New prompts include web results"
                                        )
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            .padding(.top, 6)
                        }

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
                .padding(.top, 16)
            }
            .background(AppTheme.Colors.background)
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 16)
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
                .padding(.bottom, 24)
                .background(
                    LinearGradient(colors: [AppTheme.Colors.surface.opacity(0.98), AppTheme.Colors.surface.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea(edges: .bottom)
                )
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Gradients.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
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
                    Text(actionTitle)
                        .font(AppTheme.Typography.caption.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(AppTheme.Colors.accent.opacity(0.15))
                .foregroundColor(AppTheme.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(AppTheme.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(AppTheme.Colors.outline.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)
    }
}

private struct ContextChip: View {
    let icon: String
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.accent)
                Text(title)
                    .font(AppTheme.Typography.caption.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(AppTheme.Colors.surfaceElevated.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.Colors.outline.opacity(0.3), lineWidth: 0.5)
        )
    }
}

#Preview {
    ContentView()
}
