import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingCopyConfirmation = false
    @State private var showingShareSheet = false
    @State private var isPromptExpanded = false
    @State private var showingSidebar = false
    @State private var followUpMessage: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header with prompt and stats
            VStack(spacing: 16) {
                // Prompt Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Your Question")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        Spacer()

                        if viewModel.prompt.count > 100 {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isPromptExpanded.toggle()
                                }
                            }) {
                                Text(isPromptExpanded ? "Show Less" : "Show More")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.2))
                            }
                        }
                    }

                    Text(viewModel.prompt)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        .lineSpacing(4)
                        .lineLimit(isPromptExpanded ? nil : 3)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPromptExpanded)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Stats
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.2))
                        Text("\(viewModel.totalLatency)ms")
                            .font(.system(size: 13, weight: .medium))
                    }

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.5))

                    HStack(spacing: 6) {
                        Image(systemName: "cpu.fill")
                            .font(.caption2)
                            .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.2))
                        Text("\(viewModel.responses.count) models")
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
            }
            .background(.regularMaterial)

            // Tab Bar
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
            .background(.regularMaterial)

            // Response Content
            if viewModel.selectedTab < viewModel.responses.count {
                let response = viewModel.responses[viewModel.selectedTab]
                let messages = viewModel.getConversationMessages(for: response.model)

                VStack(spacing: 0) {
                    // Messages ScrollView
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if response.hasError && messages.isEmpty {
                                // Error State (only if no conversation history)
                                VStack(spacing: 16) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(.orange)

                                    Text("Response Error")
                                        .font(.title3)
                                        .fontWeight(.semibold)

                                    Text(response.error ?? "Unknown error")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 80)
                            } else {
                                // Conversation History
                                ForEach(messages) { message in
                                    MessageBubbleView(message: message)
                                        .padding(.horizontal, 16)
                                }

                                // Show error if latest response has error
                                if response.hasError {
                                    HStack {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.orange)
                                        Text(response.error ?? "Error")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.regularMaterial)
                                    .cornerRadius(8)
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)

                    // Follow-up Input Field
                    VStack(spacing: 0) {
                        Divider()

                        HStack(spacing: 12) {
                            ZStack(alignment: .leading) {
                                if followUpMessage.isEmpty && !isInputFocused {
                                    Text("Ask a follow-up question...")
                                        .foregroundColor(.secondary.opacity(0.5))
                                        .padding(.leading, 4)
                                }

                                TextField("", text: $followUpMessage, axis: .vertical)
                                    .focused($isInputFocused)
                                    .lineLimit(1...5)
                                    .textFieldStyle(.plain)
                            }
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)

                            Button {
                                sendFollowUp(to: response.model)
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: followUpMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [Color.gray.opacity(0.3)] : [Color(red: 0.95, green: 0.5, blue: 0.2), Color(red: 0.85, green: 0.4, blue: 0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .disabled(followUpMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || response.hasError)
                        }
                        .padding(12)
                        .background(.regularMaterial)
                    }
                }

                // Bottom Action Bar
                VStack(spacing: 0) {
                    Divider()

                    HStack(spacing: 16) {
                        // Stats
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Speed")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(response.displayLatency)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }

                            if !response.displayTokens.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Tokens")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(response.displayTokens)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }

                        Spacer()

                        // Action Buttons
                        HStack(spacing: 12) {
                            // Copy Button
                            Button {
                                viewModel.copyResponse(response)
                                showingCopyConfirmation = true

                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showingCopyConfirmation = false
                                }
                            } label: {
                                Image(systemName: showingCopyConfirmation ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(showingCopyConfirmation ? .green : Color(red: 0.95, green: 0.5, blue: 0.2))
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.5))
                                    .cornerRadius(8)
                            }
                            .disabled(response.hasError)

                            // Share Button
                            Button {
                                showingShareSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.2))
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.5))
                                    .cornerRadius(8)
                            }
                            .disabled(response.hasError)
                        }
                    }
                    .padding(16)
                    .background(.regularMaterial)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingSidebar = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.25))
                }
            }

            ToolbarItem(placement: .principal) {
                if !showingSidebar {
                    Text("Results")
                        .font(.headline)
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        viewModel.copyAllResponses()
                    } label: {
                        Label("Copy All Responses", systemImage: "doc.on.doc")
                    }

                    Button(role: .destructive) {
                        viewModel.startNewChat()
                    } label: {
                        Label("New Chat", systemImage: "square.and.pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.25))
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .overlay {
            if showingSidebar {
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
        .sheet(isPresented: $showingShareSheet) {
            if viewModel.selectedTab < viewModel.responses.count {
                let response = viewModel.responses[viewModel.selectedTab]
                ShareSheet(items: [response.response])
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
                            LinearGradient(
                                colors: hasError ? [Color.orange, Color.orange] :
                                        isSelected ? [Color(red: 0.95, green: 0.5, blue: 0.2), Color(red: 0.85, green: 0.4, blue: 0.3)] :
                                        [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 8, height: 8)
                        .shadow(color: isSelected ? Color(red: 0.95, green: 0.5, blue: 0.2).opacity(0.4) : Color.clear, radius: 3, x: 0, y: 1)

                    Text(modelName)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                }

                // Underline indicator
                if isSelected {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.5, blue: 0.2), Color(red: 0.85, green: 0.4, blue: 0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.clear)
                    }
                }
            )
            .foregroundColor(isSelected ? Color(red: 0.2, green: 0.15, blue: 0.1) : .secondary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
