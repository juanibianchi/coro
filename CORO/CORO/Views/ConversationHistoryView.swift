import SwiftUI
import SwiftData

struct ConversationHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.timestamp, order: .reverse) private var conversations: [Conversation]
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.Colors.background
                    .ignoresSafeArea()

                if conversations.isEmpty {
                    // Empty State
                    VStack(spacing: 24) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 64))
                            .foregroundStyle(AppTheme.Gradients.accent)

                        VStack(spacing: 8) {
                            Text("No History Yet")
                                .font(AppTheme.Typography.title)
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text("Your conversation history will appear here")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                } else {
                    // Conversation List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(conversations) { conversation in
                                ConversationRowView(conversation: conversation)
                                    .onTapGesture {
                                        viewModel.loadConversation(conversation)
                                        dismiss()
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
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundColor(AppTheme.Colors.accent)
                    }
                }

                if !conversations.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            deleteAllConversations()
                        } label: {
                            Text("Clear All")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }

    private func deleteConversation(_ conversation: Conversation) {
        modelContext.delete(conversation)
        try? modelContext.save()
    }

    private func deleteAllConversations() {
        for conversation in conversations {
            modelContext.delete(conversation)
        }
        try? modelContext.save()
    }
}

struct ConversationRowView: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(
                    conversation.timestamp.formatted(
                        .dateTime
                            .month(.abbreviated)
                            .day()
                            .hour(.twoDigits(amPM: .abbreviated))
                            .minute()
                    )
                )
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                    Text("\(conversation.totalLatency)ms")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(AppTheme.Colors.accent)
            }

            // Prompt Preview
            Text(conversation.prompt)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2)
                .lineSpacing(4)

            // Model Count
            HStack(spacing: 8) {
                ForEach(conversation.responses.prefix(3), id: \.model) { response in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(response.hasError ? AppTheme.Colors.warning : AppTheme.Colors.modelAccent(for: response.model))
                            .frame(width: 6, height: 6)

                        Text(modelDisplayName(response.model))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }

                if conversation.responses.count > 3 {
                    Text("+\(conversation.responses.count - 3)")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.Colors.outline.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func modelDisplayName(_ modelId: String) -> String {
        switch modelId {
        case "gemini": return "Gemini"
        case "llama-70b": return "Llama 70B"
        case "llama-8b": return "Llama 8B"
        case "mixtral": return "Mixtral"
        case "deepseek": return "DeepSeek"
        default: return modelId
        }
    }
}
