import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingSettings = false
    @State private var showingSidebar = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            // Background - at the very root!
            Color(red: 0.99, green: 0.96, blue: 0.92)
                .ignoresSafeArea()

            NavigationStack {
                Group {
                    if viewModel.viewState == .loading {
                        // Loading Skeleton
                        LoadingSkeletonView(modelCount: viewModel.selectedModels.count)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbarBackground(.hidden, for: .navigationBar)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button {
                                        showingSidebar.toggle()
                                    } label: {
                                        Image(systemName: "line.3.horizontal")
                                            .font(.title3)
                                            .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.25))
                                    }
                                }

                                ToolbarItem(placement: .principal) {
                                    if !showingSidebar {
                                        Text("CORO")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.2), Color(red: 0.85, green: 0.4, blue: 0.3)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                }

                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button {
                                        showingSettings = true
                                    } label: {
                                        Image(systemName: "gearshape.fill")
                                            .font(.title3)
                                            .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.25))
                                    }
                                }
                            }
                    } else if viewModel.viewState == .success && !viewModel.responses.isEmpty {
                        // Results View
                        ResultsView(viewModel: viewModel)
                    } else {
                        // Input View
                        InputView(viewModel: viewModel)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbarBackground(.hidden, for: .navigationBar)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button {
                                        showingSidebar.toggle()
                                    } label: {
                                        Image(systemName: "line.3.horizontal")
                                            .font(.title3)
                                            .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.25))
                                    }
                                }

                                ToolbarItem(placement: .principal) {
                                    if !showingSidebar {
                                        Text("CORO")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.2), Color(red: 0.85, green: 0.4, blue: 0.3)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                }

                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button {
                                        showingSettings = true
                                    } label: {
                                        Image(systemName: "gearshape.fill")
                                            .font(.title3)
                                            .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.25))
                                    }
                                }
                            }
                    }
                }
                .background(Color.clear)
            .sheet(isPresented: $showingSettings) {
                SettingsView(apiService: viewModel.apiService)
            }
            .overlay {
                if showingSidebar {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showingSidebar = false
                            }
                        }

                    HStack(spacing: 0) {
                        SidebarView(viewModel: viewModel, isPresented: $showingSidebar)
                            .frame(width: min(UIScreen.main.bounds.width * 0.85, 400))
                            .transition(.move(edge: .leading))

                        Spacer()
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showingSidebar)
        }
            .task {
                await viewModel.loadAvailableModels()
            }
            .onAppear {
                viewModel.modelContext = modelContext
            }
            .onChange(of: viewModel.viewState) { _, newState in
                if case .success = newState {
                    viewModel.saveConversation()
                }
            }
        }
    }
}

struct InputView: View {
    @ObservedObject var viewModel: ChatViewModel
    @FocusState private var isPromptFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 40) {
                    // Spacer for top
                    Spacer()
                        .frame(height: 20)

                    // Prompt Input
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What would you like to ask?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                        ZStack(alignment: .topLeading) {
                            // Placeholder
                            if viewModel.prompt.isEmpty && !isPromptFocused {
                                Text("Try asking about anything...")
                                    .foregroundColor(.secondary.opacity(0.4))
                                    .padding(.horizontal, 6)
                                    .padding(.top, 12)
                            }

                            // Text Editor
                            TextEditor(text: $viewModel.prompt)
                                .focused($isPromptFocused)
                                .frame(minHeight: 140)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: isPromptFocused ?
                                            [Color(red: 0.95, green: 0.5, blue: 0.2).opacity(0.6), Color(red: 0.85, green: 0.4, blue: 0.3).opacity(0.6)] :
                                            [Color.white.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 24)

                    // Model Selection
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Select Models")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                            Spacer()

                            Text("\(viewModel.selectedModels.count) selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 24)

                        ModelSelectorView(viewModel: viewModel)
                    }

                    // Error Message
                    if case .error(let message) = viewModel.viewState {
                        HStack(spacing: 14) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.2))

                            Text(message)
                                .font(.body)
                                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.15))

                            Spacer()
                        }
                        .padding(20)
                        .background(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color(red: 0.95, green: 0.5, blue: 0.2).opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                    }

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.bottom, 120)
            }

            // Compare Button (Fixed at bottom)
            VStack(spacing: 0) {
                Button {
                    isPromptFocused = false
                    Task {
                        await viewModel.sendChatRequest()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if viewModel.viewState == .loading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.1)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.title3)
                            Text("Compare Models")
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        LinearGradient(
                            colors: viewModel.canSubmit ? [Color(red: 0.95, green: 0.5, blue: 0.2), Color(red: 0.85, green: 0.4, blue: 0.3)] : [Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: viewModel.canSubmit ? Color(red: 0.95, green: 0.5, blue: 0.2).opacity(0.3) : Color.clear, radius: 12, x: 0, y: 6)
                }
                .disabled(!viewModel.canSubmit || viewModel.viewState == .loading)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 30)
                .background(.regularMaterial)
            }
        }
    }
}

#Preview {
    ContentView()
}
