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
                        .lineSpacing(6)
                        .padding(16)
                        .background(
                            AppTheme.Gradients.accent.opacity(0.15)
                        )
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(AppTheme.Colors.accent.opacity(0.35), lineWidth: 1)
                        )
                } else if message.isPendingAssistant {
                    HStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                        Text("Thinking…")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(16)
                    .background(AppTheme.Colors.surfaceElevated)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(AppTheme.Colors.outline.opacity(0.2), lineWidth: 1)
                    )
                } else {
                    MarkdownText(message.content, fontSize: 16, lineSpacing: 10)
                        .padding(18)
                        .background(AppTheme.Colors.surfaceElevated)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(AppTheme.Colors.outline.opacity(0.25), lineWidth: 1)
                        )
                }
            }

            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
}
