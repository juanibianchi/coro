import SwiftUI

struct ModelSelectorView: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(viewModel.availableModels) { model in
                    ModelCard(
                        model: model,
                        isSelected: viewModel.selectedModels.contains(model.id)
                    ) {
                        viewModel.toggleModel(model.id)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 4)
        }
    }
}

struct ModelCard: View {
    let model: ModelInfo
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(
                            isSelected ? AppTheme.Gradients.accent : LinearGradient(colors: [AppTheme.Colors.outline.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 12, height: 12)
                        .shadow(color: isSelected ? AppTheme.Colors.accent.opacity(0.45) : Color.clear, radius: 4, x: 0, y: 2)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.accent)
                            .font(.title3)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(model.name)
                        .font(AppTheme.Typography.subtitle)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 40, alignment: .top)

                    Text(model.provider)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .frame(width: 160, height: 120)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.Colors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        isSelected ? AppTheme.Colors.accent.opacity(0.5) : AppTheme.Colors.outline.opacity(0.4),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: isSelected ? AppTheme.Colors.accent.opacity(0.25) : Color.black.opacity(0.08), radius: isSelected ? 15 : 10, x: 0, y: isSelected ? 8 : 5)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
