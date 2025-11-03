import XCTest
import SwiftData
@testable import CORO

final class ModelConversionTests: XCTestCase {

    // MARK: - SavedModelResponse Conversion Tests

    func testSavedModelResponseToModelResponse() {
        let savedResponse = SavedModelResponse(
            model: "gemini",
            response: "Test response",
            tokens: 100,
            latencyMs: 500,
            error: nil
        )

        let modelResponse = savedResponse.toModelResponse()

        XCTAssertEqual(modelResponse.model, "gemini")
        XCTAssertEqual(modelResponse.response, "Test response")
        XCTAssertEqual(modelResponse.tokens, 100)
        XCTAssertEqual(modelResponse.latencyMs, 500)
        XCTAssertNil(modelResponse.error)
    }

    func testSavedModelResponseWithError() {
        let savedResponse = SavedModelResponse(
            model: "gemini",
            response: "",
            tokens: nil,
            latencyMs: 100,
            error: "API Error"
        )

        let modelResponse = savedResponse.toModelResponse()

        XCTAssertEqual(modelResponse.error, "API Error")
        XCTAssertTrue(modelResponse.response.isEmpty)
        XCTAssertNil(modelResponse.tokens)
    }

    func testSavedModelResponseHasError() {
        let withError = SavedModelResponse(
            model: "gemini",
            response: "",
            tokens: nil,
            latencyMs: 100,
            error: "Error"
        )

        let withoutError = SavedModelResponse(
            model: "gemini",
            response: "Success",
            tokens: 10,
            latencyMs: 100,
            error: nil
        )

        XCTAssertTrue(withError.hasError)
        XCTAssertFalse(withoutError.hasError)
    }

    func testDisplayLatency() {
        let savedResponse = SavedModelResponse(
            model: "gemini",
            response: "Test",
            tokens: 10,
            latencyMs: 1234,
            error: nil
        )

        XCTAssertEqual(savedResponse.displayLatency, "1234ms")
    }

    func testDisplayTokens() {
        let withTokens = SavedModelResponse(
            model: "gemini",
            response: "Test",
            tokens: 150,
            latencyMs: 100,
            error: nil
        )

        let withoutTokens = SavedModelResponse(
            model: "gemini",
            response: "Test",
            tokens: nil,
            latencyMs: 100,
            error: nil
        )

        XCTAssertEqual(withTokens.displayTokens, "150 tokens")
        XCTAssertEqual(withoutTokens.displayTokens, "")
    }

    // MARK: - SavedConversationMessage Conversion Tests

    func testSavedConversationMessageToMessage() {
        let savedMessage = SavedConversationMessage(
            modelId: "gemini",
            role: "user",
            content: "Test question"
        )

        let message = savedMessage.toMessage()

        XCTAssertEqual(message.role, "user")
        XCTAssertEqual(message.content, "Test question")
    }

    func testMessageToSavedConversationMessage() {
        let message = Message(role: "assistant", content: "Test answer")

        let savedMessage = SavedConversationMessage.from(message, modelId: "gemini")

        XCTAssertEqual(savedMessage.modelId, "gemini")
        XCTAssertEqual(savedMessage.role, "assistant")
        XCTAssertEqual(savedMessage.content, "Test answer")
    }

    func testRoundTripConversion() {
        let originalMessage = Message(role: "user", content: "Original content")

        let saved = SavedConversationMessage.from(originalMessage, modelId: "test-model")
        let converted = saved.toMessage()

        XCTAssertEqual(converted.role, originalMessage.role)
        XCTAssertEqual(converted.content, originalMessage.content)
    }

    // MARK: - Conversation Model Tests

    func testConversationInitialization() {
        let responses = [
            SavedModelResponse(model: "gemini", response: "Test", tokens: 10, latencyMs: 100, error: nil)
        ]
        let messages = [
            SavedConversationMessage(modelId: "gemini", role: "user", content: "Question")
        ]

        let conversation = Conversation(
            prompt: "Test prompt",
            totalLatency: 100,
            responses: responses,
            conversationHistory: messages
        )

        XCTAssertEqual(conversation.prompt, "Test prompt")
        XCTAssertEqual(conversation.totalLatency, 100)
        XCTAssertEqual(conversation.responses.count, 1)
        XCTAssertEqual(conversation.conversationHistory.count, 1)
        XCTAssertNotNil(conversation.timestamp)
        XCTAssertNotNil(conversation.id)
    }

    func testConversationFromChatResponse() {
        let chatResponse = ChatResponse(
            responses: [
                ModelResponse(model: "gemini", response: "Answer", tokens: 10, latencyMs: 100, error: nil)
            ],
            totalLatencyMs: 100
        )

        let conversation = Conversation(from: chatResponse, prompt: "Question")

        XCTAssertEqual(conversation.prompt, "Question")
        XCTAssertEqual(conversation.totalLatency, 100)
        XCTAssertEqual(conversation.responses.count, 1)
        XCTAssertTrue(conversation.conversationHistory.isEmpty)
    }

    // MARK: - ModelInfo Tests

    func testModelInfoIsPremium() {
        let freeModel = ModelInfo(id: "test", name: "Test", provider: "Provider", cost: "free")
        let premiumModel = ModelInfo(id: "test", name: "Test", provider: "Provider", cost: "premium")

        XCTAssertFalse(freeModel.isPremium)
        XCTAssertTrue(premiumModel.isPremium)
    }

    func testModelInfoEquality() {
        let model1 = ModelInfo(id: "gemini", name: "Gemini", provider: "Google", cost: "free")
        let model2 = ModelInfo(id: "gemini", name: "Different Name", provider: "Different", cost: "premium")
        let model3 = ModelInfo(id: "llama", name: "Llama", provider: "Meta", cost: "free")

        XCTAssertEqual(model1, model2) // Same ID
        XCTAssertNotEqual(model1, model3) // Different ID
    }

    // MARK: - Message Tests

    func testMessageEquality() {
        let message1 = Message(role: "user", content: "Hello")
        let message2 = Message(role: "user", content: "Hello")
        let message3 = Message(role: "assistant", content: "Hello")
        let message4 = Message(role: "user", content: "Different")

        XCTAssertEqual(message1, message2)
        XCTAssertNotEqual(message1, message3) // Different role
        XCTAssertNotEqual(message1, message4) // Different content
    }

    // MARK: - ModelResponse Tests

    func testModelResponseEquality() {
        let response1 = ModelResponse(model: "gemini", response: "Test", tokens: 10, latencyMs: 100, error: nil)
        let response2 = ModelResponse(model: "gemini", response: "Test", tokens: 10, latencyMs: 100, error: nil)
        let response3 = ModelResponse(model: "llama", response: "Test", tokens: 10, latencyMs: 100, error: nil)

        XCTAssertEqual(response1, response2)
        XCTAssertNotEqual(response1, response3)
    }

    func testModelResponseWithError() {
        let success = ModelResponse(model: "gemini", response: "Answer", tokens: 10, latencyMs: 100, error: nil)
        let failure = ModelResponse(model: "gemini", response: "", tokens: nil, latencyMs: 100, error: "API Error")

        XCTAssertNil(success.error)
        XCTAssertNotNil(failure.error)
        XCTAssertTrue(failure.response.isEmpty)
    }
}
