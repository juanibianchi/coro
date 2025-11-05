import Foundation

/// Helper for handling error codes and providing user-friendly messages
struct ErrorCodeHelper {
    /// Get a user-friendly error message based on error code
    static func getUserFriendlyMessage(for errorCode: String, originalMessage: String = "") -> String {
        switch errorCode {
        // Authentication & Authorization
        case "authentication_failed":
            return "Authentication failed. Please check your API key in settings."
        case "api_key_missing":
            return "API key not configured. Please add your API key in settings."
        case "api_key_invalid":
            return "Invalid API key. Please check your API key in settings."
        case "unauthorized":
            return "Access denied. Please verify your credentials."

        // Rate Limiting & Quotas
        case "rate_limited":
            return "Rate limit exceeded. Please wait a moment and try again."
        case "quota_exceeded":
            return "API quota exceeded. Please check your usage limits."

        // Request Issues
        case "invalid_request":
            return "Invalid request. Please check your input and try again."
        case "invalid_model":
            return "Model not available. Please select a different model."
        case "invalid_parameters":
            return "Invalid parameters. Please adjust your settings."

        // Model/Service Issues
        case "model_overloaded":
            return "Model is currently overloaded. Please try again in a moment."
        case "model_unavailable":
            return "Model is temporarily unavailable. Please try a different model."
        case "service_unavailable":
            return "Service is temporarily unavailable. Please try again later."

        // Response Issues
        case "timeout":
            return "Request timed out. Try a shorter prompt or lower max tokens."
        case "content_filtered":
            return "Response filtered due to content policy. Please rephrase your prompt."
        case "max_tokens_reached":
            return "Response reached maximum token limit. Try increasing max tokens."

        // Network Issues
        case "network_error":
            return "Network error. Please check your connection and try again."
        case "connection_error":
            return "Connection failed. Please check your connection and try again."

        // Generic
        case "internal_error":
            return "Internal server error. Please try again later."
        case "unknown_error":
            return originalMessage.isEmpty ? "An unexpected error occurred." : "Error: \(originalMessage)"

        default:
            return originalMessage.isEmpty ? "An error occurred." : originalMessage
        }
    }

    /// Check if an error is retryable
    static func isRetryable(errorCode: String?) -> Bool {
        guard let code = errorCode else { return false }

        let retryableCodes: Set<String> = [
            "rate_limited",
            "model_overloaded",
            "service_unavailable",
            "timeout",
            "network_error",
            "connection_error"
        ]

        return retryableCodes.contains(code)
    }

    /// Get SF Symbol icon for error type
    static func getErrorIcon(for errorCode: String?) -> String {
        guard let code = errorCode else { return "exclamationmark.triangle" }

        switch code {
        case "authentication_failed", "api_key_missing", "api_key_invalid", "unauthorized":
            return "key.slash"
        case "rate_limited", "quota_exceeded":
            return "clock.badge.exclamationmark"
        case "timeout":
            return "hourglass"
        case "content_filtered":
            return "hand.raised"
        case "network_error", "connection_error":
            return "wifi.slash"
        case "model_overloaded", "service_unavailable":
            return "server.rack"
        default:
            return "exclamationmark.triangle"
        }
    }
}
