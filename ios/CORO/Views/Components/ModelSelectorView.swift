import SwiftUI

struct ModelSelectorView: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Models")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                Menu {
                    Button("Select All") {
                        viewModel.selectAllModels()
                    }

                    Button("Deselect All") {
                        viewModel.deselectAllModels()
                    }
                } label: {
                    Text(viewModel.selectedModels.isEmpty ? "None" : "\(viewModel.selectedModels.count) selected")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(viewModel.availableModels) { model in
                    ModelToggleRow(
                        model: model,
                        isSelected: viewModel.selectedModels.contains(model.id)
                    ) {
                        viewModel.toggleModel(model.id)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ModelToggleRow: View {
    let model: ModelInfo
    let isSelected: Bool
    let action: () -> Void

    var body: View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                    }
                }

                // Model Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(model.displayName)
                            .font(.body)
                            .foregroundColor(.primary)

                        if model.isPremium {
                            Text("PREMIUM")
                                .font(.caption2.bold())
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }

                    Text(model.provider)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.bold())
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
