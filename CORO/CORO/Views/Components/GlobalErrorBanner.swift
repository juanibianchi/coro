import SwiftUI

struct GlobalErrorBanner: View {
    let error: GlobalError
    let actionTitle: String?
    let action: (() -> Void)?
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: ErrorCodeHelper.getErrorIcon(for: error.code))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.Gradients.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(error.message)
                        .font(AppTheme.Typography.body.weight(.semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle = subtitleText {
                        Text(subtitle)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                Spacer(minLength: 12)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(8)
                        .background(AppTheme.Colors.surfaceElevated.opacity(0.6))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Dismiss error message")
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTheme.Typography.caption.weight(.semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(AppTheme.Gradients.accent)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.Colors.outline.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        .accessibilityElement(children: .combine)
    }

    private var subtitleText: String? {
        guard let code = error.code else { return nil }

        if code == "rate_limited", let retryAfter = error.retryAfter {
            if retryAfter > 0 {
                return "Please try again in about \(retryAfter) seconds."
            } else {
                return "Please wait a moment before trying again."
            }
        }

        return nil
    }
}
