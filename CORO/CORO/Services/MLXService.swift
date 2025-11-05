import Foundation
import MLX
import MLXNN
import MLXLLM
import MLXLMCommon

class MLXService {
    var isModelLoaded = false
    var downloadProgress: Double = 0

    private var chatSession: ChatSession?
    private let modelId = "mlx-community/Llama-3.2-1B-Instruct-4bit"

    init() {
        #if targetEnvironment(simulator)
        print("MLXService initialized (Simulator mode - on-device inference disabled)")
        #else
        print("MLXService initialized (Device mode - GPU acceleration enabled)")
        #endif
    }

    /// Generate response using on-device model
    func generate(
        prompt: String,
        temperature: Float = 0.7,
        maxTokens: Int = 512,
        conversationHistory: [Message] = []
    ) async throws -> ModelResponse {
        let startTime = Date()

        // Check if running on simulator
        #if targetEnvironment(simulator)
        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)
        return ModelResponse(
            model: "llama-3.2-1b-local",
            response: "",
            tokens: nil,
            latencyMs: latencyMs,
            error: "⚠️ On-device inference is not available on iOS Simulator. Please test on a real device (iPhone 13 or later) to use the local Llama 3.2 1B model.",
            errorCode: "model_unavailable"
        )
        #else
        do {
            // Load model if not already loaded
            if chatSession == nil {
                print("Loading Llama 3.2 1B model from: \(modelId)")

                // Load the model with progress tracking (returns ModelContext)
                print("Starting model download/load...")
                let modelContext = try await loadModel(
                    id: modelId,
                    progressHandler: { [weak self] progress in
                        Task { @MainActor in
                            self?.downloadProgress = progress.fractionCompleted
                            print("Download progress: \(Int(progress.fractionCompleted * 100))%")
                        }
                    }
                )

                print("Model context loaded, creating chat session...")

                // Create chat session with generation parameters
                let generateParams = GenerateParameters(
                    maxTokens: maxTokens,
                    temperature: temperature,
                    topP: 0.9
                )

                chatSession = ChatSession(modelContext, generateParameters: generateParams)
                isModelLoaded = true
                print("Model loaded successfully!")
            }

            guard let session = chatSession else {
                throw NSError(domain: "MLXService", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
            }

            // Build the full prompt including conversation history
            var fullPrompt = ""
            if !conversationHistory.isEmpty {
                fullPrompt = formatConversationHistory(conversationHistory)
            }
            fullPrompt += prompt

            // Generate response
            print("Generating response...")
            let response = try await session.respond(to: fullPrompt)

            let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)

            // Estimate token count (rough approximation)
            let tokens = response.split(separator: " ").count

            return ModelResponse(
                model: "llama-3.2-1b-local",
                response: response,
                tokens: tokens,
                latencyMs: latencyMs,
                error: nil,
                errorCode: nil
            )

        } catch {
            let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)
            return ModelResponse(
                model: "llama-3.2-1b-local",
                response: "",
                tokens: nil,
                latencyMs: latencyMs,
                error: "On-device inference error: \(error.localizedDescription)",
                errorCode: "internal_error"
            )
        }
        #endif
    }

    /// Format conversation history for the prompt
    private func formatConversationHistory(_ history: [Message]) -> String {
        var formatted = ""
        for message in history {
            if message.role == "user" {
                formatted += "User: \(message.content)\n"
            } else {
                formatted += "Assistant: \(message.content)\n"
            }
        }
        return formatted
    }

    /// Check if model is available locally
    func isModelAvailable() -> Bool {
        return isModelLoaded
    }
}
