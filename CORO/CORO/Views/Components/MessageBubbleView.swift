import SwiftUI

struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.isUser ? "You" : "Assistant")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                if message.isUser {
                    Text(message.content)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineSpacing(4)
                        .padding(14)
                        .background(
                            AppTheme.Gradients.accent.opacity(0.15)
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(AppTheme.Colors.accent.opacity(0.35), lineWidth: 1)
                        )
                } else if message.isPendingAssistant {
                    HStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                        Text("Assistant is thinking…")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(14)
                    .background(AppTheme.Colors.surfaceElevated)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppTheme.Colors.outline.opacity(0.2), lineWidth: 1)
                    )
                } else {
                    MarkdownText(message.content)
                        .padding(14)
                        .background(AppTheme.Colors.surfaceElevated)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(AppTheme.Colors.outline.opacity(0.4), lineWidth: 1)
                        )
                }
            }

            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
}
