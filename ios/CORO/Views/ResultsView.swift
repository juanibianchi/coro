import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingCopyConfirmation = false

    var body: View {
        VStack(spacing: 0) {
            // Header with prompt and stats
            VStack(spacing: 8) {
                Text(viewModel.prompt)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal)

                Text("Total: \(viewModel.totalLatency)ms • \(viewModel.responses.count) models")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)

            // Tab Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.responses.enumerated()), id: \.element.id) { index, response in
                        TabButton(
                            modelName: viewModel.getModelName(response.model),
                            isSelected: viewModel.selectedTab == index,
                            hasError: response.hasError,
                            color: viewModel.getModelColor(response.model)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedTab = index
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // Response Content
            if viewModel.selectedTab < viewModel.responses.count {
                let response = viewModel.responses[viewModel.selectedTab]

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if response.hasError {
                            // Error State
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.orange)

                                Text("Error")
                                    .font(.title2.bold())

                                Text(response.error ?? "Unknown error")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            // Success State
                            Text(response.response)
                                .font(.body)
                                .lineSpacing(6)
                                .textSelection(.enabled)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))

                // Bottom Action Bar
                HStack(spacing: 16) {
                    // Copy Button
                    Button {
                        viewModel.copyResponse(response)
                        showingCopyConfirmation = true

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showingCopyConfirmation = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: showingCopyConfirmation ? "checkmark" : "doc.on.doc")
                            Text(showingCopyConfirmation ? "Copied!" : "Copy")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(response.hasError)

                    // Stats
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(response.displayLatency)
                            .font(.caption.bold())
                        if !response.displayTokens.isEmpty {
                            Text(response.displayTokens)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.viewState = .idle
                    viewModel.responses = []
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        viewModel.copyAllResponses()
                    } label: {
                        Label("Copy All Responses", systemImage: "doc.on.doc")
                    }

                    Button(role: .destructive) {
                        viewModel.viewState = .idle
                        viewModel.responses = []
                        viewModel.prompt = ""
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

struct TabButton: View {
    let modelName: String
    let isSelected: Bool
    let hasError: Bool
    let color: Color
    let action: () -> Void

    var body: View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(hasError ? Color.orange : color)
                    .frame(width: 8, height: 8)

                Text(modelName)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .foregroundColor(isSelected ? .blue : .primary)
        }
    }
}
