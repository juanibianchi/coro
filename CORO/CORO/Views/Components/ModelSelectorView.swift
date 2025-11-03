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
                            LinearGradient(
                                colors: isSelected ? [Color(red: 0.95, green: 0.5, blue: 0.2), Color(red: 0.85, green: 0.4, blue: 0.3)] : [Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 12, height: 12)
                        .shadow(color: isSelected ? Color(red: 0.95, green: 0.5, blue: 0.2).opacity(0.4) : Color.clear, radius: 4, x: 0, y: 2)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.2))
                            .font(.title3)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(model.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 40, alignment: .top)

                    Text(model.provider)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 160, height: 120)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        LinearGradient(
                            colors: isSelected ?
                                [Color(red: 0.95, green: 0.5, blue: 0.2).opacity(0.6), Color(red: 0.85, green: 0.4, blue: 0.3).opacity(0.6)] :
                                [Color.white.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: isSelected ? Color(red: 0.95, green: 0.5, blue: 0.2).opacity(0.2) : Color.black.opacity(0.08), radius: isSelected ? 15 : 10, x: 0, y: isSelected ? 8 : 5)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
