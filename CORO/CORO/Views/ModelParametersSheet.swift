import SwiftUI

struct ModelParametersSheet: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Temperature Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Temperature")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Temperature")
                                        .font(AppTheme.Typography.subtitle)
                                        .foregroundColor(AppTheme.Colors.textPrimary)

                                    Spacer()

                                    Text(String(format: "%.1f", viewModel.temperature))
                                        .font(AppTheme.Typography.subtitle)
                                        .foregroundColor(AppTheme.Colors.accent)
                                }

                                Slider(value: $viewModel.temperature, in: 0.0...2.0, step: 0.1)
                                    .tint(AppTheme.Colors.accent)

                                Text("Controls randomness. Lower = more focused, Higher = more creative")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppTheme.Colors.surfaceElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(AppTheme.Colors.outline.opacity(0.4), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

                        // Max Tokens Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Max Tokens")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Maximum Tokens")
                                        .font(AppTheme.Typography.subtitle)
                                        .foregroundColor(AppTheme.Colors.textPrimary)

                                    Spacer()

                                    Text("\(viewModel.maxTokens)")
                                        .font(AppTheme.Typography.subtitle)
                                        .foregroundColor(AppTheme.Colors.accent)
                                }

                                Slider(value: Binding(
                                    get: { Double(viewModel.maxTokens) },
                                    set: { viewModel.maxTokens = Int($0) }
                                ), in: 100...8000, step: 100)
                                    .tint(AppTheme.Colors.accent)

                                Text("Maximum length of generated response (in tokens)")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppTheme.Colors.surfaceElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(AppTheme.Colors.outline.opacity(0.4), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

                        // Top-P Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Top-P (Optional)")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: Binding(
                                    get: { viewModel.topP != nil },
                                    set: { enabled in
                                        viewModel.topP = enabled ? 1.0 : nil
                                    }
                                )) {
                                    Text("Enable Top-P")
                                        .font(AppTheme.Typography.subtitle)
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                }
                                .tint(AppTheme.Colors.accent)

                                if viewModel.topP != nil {
                                    HStack {
                                        Text("Top-P Value")
                                            .font(AppTheme.Typography.subtitle)
                                            .foregroundColor(AppTheme.Colors.textPrimary)

                                        Spacer()

                                        Text(String(format: "%.2f", viewModel.topP ?? 1.0))
                                            .font(AppTheme.Typography.subtitle)
                                            .foregroundColor(AppTheme.Colors.accent)
                                    }

                                    Slider(value: Binding(
                                        get: { viewModel.topP ?? 1.0 },
                                        set: { viewModel.topP = $0 }
                                    ), in: 0.0...1.0, step: 0.05)
                                        .tint(AppTheme.Colors.accent)
                                }

                                Text("Nucleus sampling: considers tokens with cumulative probability of top-p. Lower = more deterministic")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppTheme.Colors.surfaceElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(AppTheme.Colors.outline.opacity(0.4), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

                        // Reset Button
                        Button {
                            viewModel.temperature = 0.7
                            viewModel.maxTokens = 2000
                            viewModel.topP = nil
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset to Defaults")
                            }
                            .font(AppTheme.Typography.subtitle)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.Colors.surfaceElevated)
                            .foregroundColor(AppTheme.Colors.accent)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Model Parameters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.Colors.accent)
                    }
                }
            }
        }
    }
}
