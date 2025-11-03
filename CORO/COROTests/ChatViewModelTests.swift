import XCTest
@testable import CORO

@MainActor
final class ChatViewModelTests: XCTestCase {

    var viewModel: ChatViewModel!
    var mockAPIService: MockAPIService!
    var mockMLXService: MockMLXService!

    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService()
        mockMLXService = MockMLXService()
        viewModel = ChatViewModel(apiService: mockAPIService, mlxService: mockMLXService)
    }

    override func tearDown() {
        viewModel = nil
        mockAPIService = nil
        mockMLXService = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertEqual(viewModel.prompt, "")
        XCTAssertTrue(viewModel.selectedModels.isEmpty == false, "Should have default models selected")
        XCTAssertEqual(viewModel.viewState, .idle)
        XCTAssertTrue(viewModel.responses.isEmpty)
        XCTAssertEqual(viewModel.totalLatency, 0)
    }

    func testLoadDefaultModels() {
        XCTAssertFalse(viewModel.availableModels.isEmpty)
        XCTAssertTrue(viewModel.availableModels.contains { $0.id == "llama-3.2-1b-local" })
    }

    // MARK: - Model Selection Tests

    func testToggleModel() {
        let modelId = "gemini"
        let initiallySelected = viewModel.selectedModels.contains(modelId)

        viewModel.toggleModel(modelId)

        XCTAssertNotEqual(viewModel.selectedModels.contains(modelId), initiallySelected)
    }

    func testSelectAllModels() {
        viewModel.selectedModels.removeAll()

        viewModel.selectAllModels()

        XCTAssertEqual(viewModel.selectedModels.count, viewModel.availableModels.count)
    }

    func testDeselectAllModels() {
        viewModel.selectAllModels()

        viewModel.deselectAllModels()

        XCTAssertTrue(viewModel.selectedModels.isEmpty)
    }

    // MARK: - Validation Tests

    func testCanSubmitWithEmptyPrompt() {
        viewModel.prompt = ""
        viewModel.selectAllModels()

        XCTAssertFalse(viewModel.canSubmit)
    }

    func testCanSubmitWithNoModels() {
        viewModel.prompt = "Test prompt"
        viewModel.deselectAllModels()

        XCTAssertFalse(viewModel.canSubmit)
    }

    func testCanSubmitWithValidInput() {
        viewModel.prompt = "Test prompt"
        viewModel.selectAllModels()

        XCTAssertTrue(viewModel.canSubmit)
    }

    // MARK: - Chat Request Tests

    func testSendChatRequestWithEmptyPrompt() async {
        viewModel.prompt = ""
        viewModel.selectedModels = ["gemini"]

        await viewModel.sendChatRequest()

        if case .error(let message) = viewModel.viewState {
            XCTAssertTrue(message.contains("prompt"))
        } else {
            XCTFail("Expected error state")
        }
    }

    func testSendChatRequestWithNoModels() async {
        viewModel.prompt = "Test"
        viewModel.selectedModels = []

        await viewModel.sendChatRequest()

        if case .error(let message) = viewModel.viewState {
            XCTAssertTrue(message.contains("model"))
        } else {
            XCTFail("Expected error state")
        }
    }

    func testSendChatRequestSuccess() async {
        viewModel.prompt = "Test prompt"
        viewModel.selectedModels = ["gemini"]

        mockAPIService.mockResponse = ChatResponse(
            responses: [
                ModelResponse(model: "gemini", response: "Test response", tokens: 10, latencyMs: 100, error: nil)
            ],
            totalLatencyMs: 100
        )

        await viewModel.sendChatRequest()

        XCTAssertEqual(viewModel.viewState, .success)
        XCTAssertEqual(viewModel.responses.count, 1)
        XCTAssertEqual(viewModel.responses.first?.model, "gemini")
    }

    func testSendChatRequestWithError() async {
        viewModel.prompt = "Test prompt"
        viewModel.selectedModels = ["gemini"]

        mockAPIService.shouldFail = true
        mockAPIService.errorMessage = "Network error"

        await viewModel.sendChatRequest()

        if case .error(let message) = viewModel.viewState {
            XCTAssertTrue(message.contains("Network error"))
        } else {
            XCTFail("Expected error state")
        }
    }

    // MARK: - Conversation History Tests

    func testConversationHistoryUpdates() async {
        viewModel.prompt = "First question"
        viewModel.selectedModels = ["gemini"]

        mockAPIService.mockResponse = ChatResponse(
            responses: [
                ModelResponse(model: "gemini", response: "First answer", tokens: 10, latencyMs: 100, error: nil)
            ],
            totalLatencyMs: 100
        )

        await viewModel.sendChatRequest()

        XCTAssertEqual(viewModel.conversationHistory["gemini"]?.count, 2) // user + assistant
        XCTAssertEqual(viewModel.conversationHistory["gemini"]?.first?.role, "user")
        XCTAssertEqual(viewModel.conversationHistory["gemini"]?.first?.content, "First question")
    }

    func testStartNewChat() {
        viewModel.prompt = "Test"
        viewModel.responses = [
            ModelResponse(model: "gemini", response: "Test", tokens: 10, latencyMs: 100, error: nil)
        ]
        viewModel.conversationHistory = ["gemini": [Message(role: "user", content: "Test")]]
        viewModel.viewState = .success

        viewModel.startNewChat()

        XCTAssertEqual(viewModel.prompt, "")
        XCTAssertTrue(viewModel.responses.isEmpty)
        XCTAssertTrue(viewModel.conversationHistory.isEmpty)
        XCTAssertEqual(viewModel.viewState, .idle)
    }

    // MARK: - Model Routing Tests

    func testCloudAndLocalModelSeparation() async {
        viewModel.prompt = "Test prompt"
        viewModel.selectedModels = ["gemini", "llama-3.2-1b-local"]

        mockAPIService.mockResponse = ChatResponse(
            responses: [
                ModelResponse(model: "gemini", response: "Cloud response", tokens: 10, latencyMs: 100, error: nil)
            ],
            totalLatencyMs: 100
        )

        mockMLXService.mockResponse = ModelResponse(
            model: "llama-3.2-1b-local",
            response: "Local response",
            tokens: 10,
            latencyMs: 50,
            error: nil
        )

        await viewModel.sendChatRequest()

        XCTAssertEqual(viewModel.responses.count, 2)
        XCTAssertTrue(mockAPIService.sendChatRequestCalled)
        XCTAssertTrue(mockMLXService.generateCalled)
    }

    // MARK: - Helper Methods Tests

    func testGetModelName() {
        let modelName = viewModel.getModelName("gemini")
        XCTAssertFalse(modelName.isEmpty)
    }

    func testGetModelColor() {
        let color = viewModel.getModelColor("gemini")
        XCTAssertNotNil(color)
    }
}

// MARK: - Mock Services

class MockAPIService: APIService {
    var mockResponse: ChatResponse?
    var shouldFail = false
    var errorMessage = "Mock error"
    var sendChatRequestCalled = false

    override func sendChatRequest(_ request: ChatRequest) async throws -> ChatResponse {
        sendChatRequestCalled = true

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

class MockMLXService: MLXService {
    var mockResponse: ModelResponse?
    var shouldFail = false
    var errorMessage = "Mock MLX error"
    var generateCalled = false

    override func generate(
        prompt: String,
        temperature: Float,
        maxTokens: Int,
        conversationHistory: [Message]
    ) async throws -> ModelResponse {
        generateCalled = true

        if shouldFail {
            throw NSError(domain: "MockMLXService", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        if let response = mockResponse {
            return response
        }

        return ModelResponse(
            model: "llama-3.2-1b-local",
            response: "Mock response",
            tokens: 10,
            latencyMs: 50,
            error: nil
        )
    }
}
