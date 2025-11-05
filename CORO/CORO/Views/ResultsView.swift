import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: ChatViewModel
    let onClose: () -> Void
    let onOpenSettings: () -> Void
    @State private var showingCopyConfirmation = false
    @State private var showingShareSheet = false
    @State private var isPromptExpanded = false
    @State private var showingSidebar = false
    @State private var followUpMessage: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
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
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                headerSection
                tabSection
                responseSection
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingSidebar = false
                    onClose()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.backward")
                        Text("Home")
                            .font(AppTheme.Typography.caption.weight(.semibold))
                    }
                }
                .foregroundColor(AppTheme.Colors.accent)
            }

            ToolbarItem(placement: .principal) {
                if !showingSidebar {
                    Text("Perspectives")
                        .font(AppTheme.Typography.subtitle)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingSidebar = true
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }

                    Button {
                        viewModel.copyAllResponses()
                    } label: {
                        Label("Copy All Responses", systemImage: "doc.on.doc")
                    }

                    Button {
                        onOpenSettings()
                    } label: {
                        Label("Open Settings", systemImage: "gearshape")
                    }

                    Button(role: .destructive) {
                        showingSidebar = false
                        onClose()
                        viewModel.startNewChat()
                    } label: {
                        Label("New Chat", systemImage: "square.and.pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundColor(AppTheme.Colors.accent)
                        .symbolRenderingMode(.hierarchical)
                        .font(.title3)
                }
            }
        }
        .overlay { sidebarOverlay }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showingSidebar)
        .sheet(isPresented: $showingShareSheet) {
            if let response = currentResponse {
                ShareSheet(items: [response.response])
            }
        }
    }

    private func primaryAction(for error: GlobalError) -> (title: String, handler: () -> Void)? {
        guard let code = error.code else { return nil }

        switch code {
        case "authentication_failed", "api_key_missing", "api_key_invalid", "unauthorized":
            return ("Open Settings", onOpenSettings)
        default:
            return nil
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            promptCard
            statsRow
        }
        .background(AppTheme.Colors.surface.opacity(0.95))
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your Question")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                if viewModel.displayedPrompt.count > 100 {
                    Button(action: togglePromptExpansion) {
                        Text(isPromptExpanded ? "Show Less" : "Show More")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.accent)
                    }
                }
            }

            Text(viewModel.displayedPrompt)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineSpacing(4)
                .lineLimit(isPromptExpanded ? nil : 3)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPromptExpanded)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.Colors.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.Colors.outline.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.caption2)
                    .foregroundColor(AppTheme.Colors.accent)
                Text("\(viewModel.totalLatency)ms")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Text("•")
                .font(.caption2)
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))

            HStack(spacing: 6) {
                Image(systemName: "cpu.fill")
                    .font(.caption2)
                    .foregroundColor(AppTheme.Colors.accent)
                Text("\(viewModel.responses.count) models")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private var tabSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.responses.enumerated()), id: \.element.id) { index, response in
                    TabButton(
                        modelName: viewModel.getModelName(response.model),
                        isSelected: viewModel.selectedTab == index,
                        hasError: response.hasError,
                        color: viewModel.getModelColor(response.model)
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.selectedTab = index
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(AppTheme.Colors.surface.opacity(0.95))
    }

    @ViewBuilder
    private var responseSection: some View {
        if let response = currentResponse {
            responseContent(for: response)
        } else {
            Spacer()
        }
    }

    private var currentResponse: ModelResponse? {
        guard viewModel.selectedTab < viewModel.responses.count else { return nil }
        return viewModel.responses[viewModel.selectedTab]
    }

    private func togglePromptExpansion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isPromptExpanded.toggle()
        }
    }

    @ViewBuilder
    private func responseContent(for response: ModelResponse) -> some View {
        let messages = viewModel.getConversationMessages(for: response.model)

        VStack(spacing: 0) {
            responseScroll(for: response, messages: messages)
            followUpSection(for: response)
            actionBar(for: response)
        }
    }

    private func responseScroll(for response: ModelResponse, messages: [Message]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if response.hasError && messages.isEmpty {
                    errorPlaceholder(for: response)
                } else {
                    ForEach(messages) { message in
                        MessageBubbleView(message: message)
                            .padding(.horizontal, 16)
                    }

                    if response.hasError {
                        errorBanner(for: response)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.surface.opacity(0.9))
    }

    private func followUpSection(for response: ModelResponse) -> some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                ZStack(alignment: .leading) {
                    if followUpMessage.isEmpty && !isInputFocused {
                        Text("Ask a follow-up question...")
                            .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))
                            .padding(.leading, 4)
                    }

                    TextField("", text: $followUpMessage, axis: .vertical)
                        .focused($isInputFocused)
                        .lineLimit(1...5)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(AppTheme.Colors.surfaceElevated)
                .cornerRadius(12)

                Button {
                    sendFollowUp(to: response.model)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.Gradients.accent)
                        .opacity(followUpMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || response.hasError ? 0.35 : 1.0)
                }
                .disabled(followUpMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || response.hasError)

                Menu {
                    Button {
                        broadcastFollowUp(message: followUpMessage, excluding: response.model)
                    } label: {
                        Label("Ask every model", systemImage: "square.stack.3d.up.forward")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(AppTheme.Colors.accent)
                        .opacity(followUpMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.35 : 1.0)
                }
                .disabled(followUpMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12)
            .background(AppTheme.Colors.surface.opacity(0.95))
        }
    }

    private func actionBar(for response: ModelResponse) -> some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 16) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speed")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        Text(response.displayLatency)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }

                    if !response.displayTokens.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tokens")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Text(response.displayTokens)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        viewModel.copyResponse(response)
                        showingCopyConfirmation = true

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showingCopyConfirmation = false
                        }
                    } label: {
                        Image(systemName: showingCopyConfirmation ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(showingCopyConfirmation ? AppTheme.Colors.success : AppTheme.Colors.accent)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.Colors.surfaceElevated)
                            .cornerRadius(8)
                    }
                    .disabled(response.hasError)

                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.accent)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.Colors.surfaceElevated)
                            .cornerRadius(8)
                    }
                    .disabled(response.hasError)
                }
            }
            .padding(16)
            .background(AppTheme.Colors.surface.opacity(0.95))
        }
    }

    @ViewBuilder
    private func errorPlaceholder(for response: ModelResponse) -> some View {
        VStack(spacing: 16) {
            Image(systemName: ErrorCodeHelper.getErrorIcon(for: response.errorCode))
                .font(.system(size: 44))
                .foregroundColor(AppTheme.Colors.warning)

            Text("Response Error")
                .font(AppTheme.Typography.subtitle)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text(response.userFriendlyError)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if ErrorCodeHelper.isRetryable(errorCode: response.errorCode) {
                Button {
                    Task { await viewModel.retryFailedModel(response.model) }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                            .font(AppTheme.Typography.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.Gradients.accent)
                    .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func errorBanner(for response: ModelResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: ErrorCodeHelper.getErrorIcon(for: response.errorCode))
                    .foregroundColor(AppTheme.Colors.warning)
                Text(response.userFriendlyError)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            if ErrorCodeHelper.isRetryable(errorCode: response.errorCode) {
                Button {
                    Task { await viewModel.retryFailedModel(response.model) }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                        Text("Retry")
                            .font(AppTheme.Typography.caption)
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.surfaceElevated)
        .cornerRadius(8)
    }

    private var sidebarOverlay: some View {
        Group {
            if showingSidebar {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showingSidebar = false
                        }
                    }
                    .overlay(
                        HStack(spacing: 0) {
                            SidebarView(viewModel: viewModel, isPresented: $showingSidebar)
                                .frame(width: min(UIScreen.main.bounds.width * 0.85, 400))
                                .transition(.move(edge: .leading))

                            Spacer()
                        }
                    )
            }
        }
    }
    private func sendFollowUp(to modelId: String) {
        let message = followUpMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        // Clear input
        followUpMessage = ""
        isInputFocused = false

        // Send message
        Task {
            await viewModel.sendFollowUpMessage(to: modelId, message: message)
        }
    }

    private func broadcastFollowUp(message: String, excluding excludedModel: String?) {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        followUpMessage = ""
        isInputFocused = false

        Task {
            await viewModel.sendFollowUpToAllModels(message: trimmed, excluding: excludedModel)
        }
    }
}

// Share Sheet Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct TabButton: View {
    let modelName: String
    let isSelected: Bool
    let hasError: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(
                            hasError
                                ? LinearGradient(colors: [AppTheme.Colors.warning, AppTheme.Colors.warning.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: isSelected ? [color, color.opacity(0.85)] : [AppTheme.Colors.outline.opacity(0.5), AppTheme.Colors.outline.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 8, height: 8)
                        .shadow(color: isSelected ? color.opacity(0.4) : Color.clear, radius: 3, x: 0, y: 1)

                    Text(modelName)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                }

                // Underline indicator
                if isSelected {
                    Rectangle()
                        .fill(LinearGradient(colors: [color, color.opacity(0.85)], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 3)
                        .cornerRadius(1.5)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.Colors.surfaceElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(color.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: color.opacity(0.25), radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.clear)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
