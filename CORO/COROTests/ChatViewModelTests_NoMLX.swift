import XCTest
@testable import CORO

// Simplified tests that don't require MLX packages
// Use this file if you're having trouble with package dependencies

@MainActor
final class ChatViewModelTests_NoMLX: XCTestCase {

    var viewModel: ChatViewModel!
    var mockAPIService: MockAPIService_Simple!

    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService_Simple()
        // Use only API service, not MLX
        viewModel = ChatViewModel(apiService: mockAPIService)
    }

    override func tearDown() {
        viewModel = nil
        mockAPIService = nil
        super.tearDown()
    }

    // MARK: - Basic Tests (No MLX Required)

    func testInitialization() {
        XCTAssertEqual(viewModel.prompt, "")
        XCTAssertEqual(viewModel.viewState, .idle)
        XCTAssertTrue(viewModel.responses.isEmpty)
    }

    func testPromptValidation() {
        // Empty prompt
        viewModel.prompt = ""
        viewModel.selectedModels = ["gemini"]
        XCTAssertFalse(viewModel.canSubmit)

        // Valid prompt
        viewModel.prompt = "Test"
        XCTAssertTrue(viewModel.canSubmit)

        // Whitespace only
        viewModel.prompt = "   "
        XCTAssertFalse(viewModel.canSubmit)
    }

    func testModelSelection() {
        let initialCount = viewModel.selectedModels.count

        viewModel.deselectAllModels()
        XCTAssertTrue(viewModel.selectedModels.isEmpty)

        viewModel.toggleModel("gemini")
        XCTAssertTrue(viewModel.selectedModels.contains("gemini"))

        viewModel.toggleModel("gemini")
        XCTAssertFalse(viewModel.selectedModels.contains("gemini"))

        viewModel.selectAllModels()
        XCTAssertEqual(viewModel.selectedModels.count, viewModel.availableModels.count)
    }

    func testStartNewChat() {
        viewModel.prompt = "Test"
        viewModel.responses = [
            ModelResponse(model: "gemini", response: "Test", tokens: 10, latencyMs: 100, error: nil)
        ]
        viewModel.viewState = .success

        viewModel.startNewChat()

        XCTAssertEqual(viewModel.prompt, "")
        XCTAssertTrue(viewModel.responses.isEmpty)
        XCTAssertEqual(viewModel.viewState, .idle)
    }

    func testGetModelName() {
        let name = viewModel.getModelName("gemini")
        XCTAssertFalse(name.isEmpty)
    }

    func testGetModelColor() {
        let color = viewModel.getModelColor("gemini")
        XCTAssertNotNil(color)
    }

    func testViewStateTransitions() {
        XCTAssertEqual(viewModel.viewState, .idle)

        viewModel.viewState = .loading
        XCTAssertEqual(viewModel.viewState, .loading)

        viewModel.viewState = .success
        XCTAssertEqual(viewModel.viewState, .success)

        viewModel.viewState = .error("Test error")
        if case .error(let message) = viewModel.viewState {
            XCTAssertEqual(message, "Test error")
        } else {
            XCTFail("Expected error state")
        }
    }

    func testCannotSubmitWithNoModels() {
        viewModel.prompt = "Valid prompt"
        viewModel.deselectAllModels()

        XCTAssertFalse(viewModel.canSubmit)
    }

    func testCanSubmitWithValidInput() {
        viewModel.prompt = "Valid prompt"
        viewModel.selectedModels = ["gemini"]

        XCTAssertTrue(viewModel.canSubmit)
    }

    func testResponsesInitiallyEmpty() {
        XCTAssertTrue(viewModel.responses.isEmpty)
        XCTAssertEqual(viewModel.totalLatency, 0)
    }

    func testConversationHistoryInitiallyEmpty() {
        XCTAssertTrue(viewModel.conversationHistory.isEmpty)
    }

    func testSelectedTabInitiallyZero() {
        XCTAssertEqual(viewModel.selectedTab, 0)
    }

    func testAvailableModelsLoadedOnInit() {
        XCTAssertFalse(viewModel.availableModels.isEmpty)
        XCTAssertTrue(viewModel.availableModels.contains { $0.id == "gemini" })
    }

    func testMultipleModelSelection() {
        viewModel.deselectAllModels()

        viewModel.toggleModel("gemini")
        viewModel.toggleModel("llama-8b")

        XCTAssertEqual(viewModel.selectedModels.count, 2)
        XCTAssertTrue(viewModel.selectedModels.contains("gemini"))
        XCTAssertTrue(viewModel.selectedModels.contains("llama-8b"))
    }

    // MARK: - Async Tests (Cloud Models Only)

    func testSendRequestWithEmptyPromptFails() async {
        viewModel.prompt = ""
        viewModel.selectedModels = ["gemini"]

        await viewModel.sendChatRequest()

        if case .error(let message) = viewModel.viewState {
            XCTAssertTrue(message.contains("prompt") || message.contains("enter"))
        } else {
            XCTFail("Expected error state for empty prompt")
        }
    }

    func testSendRequestWithNoModels() async {
        viewModel.prompt = "Test"
        viewModel.deselectAllModels()

        await viewModel.sendChatRequest()

        if case .error(let message) = viewModel.viewState {
            XCTAssertTrue(message.contains("model") || message.contains("select"))
        } else {
            XCTFail("Expected error state for no models")
        }
    }
}

// MARK: - Simplified Mock Service

class MockAPIService_Simple: APIService {
    var mockResponse: ChatResponse?
    var shouldFail = false
    var errorMessage = "Mock error"

    override func sendChatRequest(_ request: ChatRequest) async throws -> ChatResponse {
        if shouldFail {
            throw NSError(domain: "MockAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        if let response = mockResponse {
            return response
        }

        return ChatResponse(responses: [], totalLatencyMs: 0)
    }

    override func fetchAvailableModels() async throws -> [ModelInfo] {
        return [
            ModelInfo(id: "gemini", name: "Gemini", provider: "Google", cost: "free"),
            ModelInfo(id: "llama-8b", name: "Llama 8B", provider: "Groq", cost: "free")
        ]
    }
}
