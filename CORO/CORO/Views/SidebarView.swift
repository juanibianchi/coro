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
            Color(red: 0.99, green: 0.96, blue: 0.92)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with New Chat button
                VStack(spacing: 16) {
                    HStack {
                        Text("CORO")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.2), Color(red: 0.85, green: 0.4, blue: 0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Spacer()

                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .symbolRenderingMode(.hierarchical)
                        }
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
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.5, blue: 0.2), Color(red: 0.85, green: 0.4, blue: 0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(20)
                .background(.regularMaterial)

                // Conversations List
                if conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text("No conversations yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                .lineLimit(2)

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(conversation.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(conversation.responses.count)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.2))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
        )
    }
}
