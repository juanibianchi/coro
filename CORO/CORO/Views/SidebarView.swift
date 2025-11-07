import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.timestamp, order: .reverse) private var conversations: [Conversation]
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with New Chat button
                VStack(spacing: 16) {
                    HStack {
                        Text("Coro")
                            .font(AppTheme.Typography.title)
                            .foregroundStyle(AppTheme.Gradients.accent)

                        Spacer()
                    }

                    // New Chat Button
                    Button {
                        viewModel.startNewChat()
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 16, weight: .semibold))
                            Text("New Chat")
                                .font(AppTheme.Typography.subtitle)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.Gradients.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(20)
                .background(AppTheme.Colors.surfaceElevated)

                // Conversations List
                if conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))

                        Text("No conversations yet")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(conversations) { conversation in
                                SidebarConversationRow(conversation: conversation)
                                    .onTapGesture {
                                        viewModel.loadConversation(conversation)
                                        isPresented = false
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteConversation(conversation)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
    }

    private func deleteConversation(_ conversation: Conversation) {
        modelContext.delete(conversation)
        try? modelContext.save()
    }
}

struct SidebarConversationRow: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(conversation.prompt)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Text(conversation.timestamp, style: .relative)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Spacer()

                Text("\(conversation.responses.count)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.accent)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.Colors.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(AppTheme.Colors.outline.opacity(0.4), lineWidth: 0.5)
        )
    }
}
