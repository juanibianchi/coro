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
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                if message.isUser {
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        .lineSpacing(4)
                        .padding(14)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.5, blue: 0.2).opacity(0.15), Color(red: 0.85, green: 0.4, blue: 0.3).opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color(red: 0.95, green: 0.5, blue: 0.2).opacity(0.3), lineWidth: 1)
                        )
                } else {
                    MarkdownText(message.content)
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
}
