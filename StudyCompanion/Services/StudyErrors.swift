import Foundation
import FoundationModels

// MARK: - Per-Service Errors

enum PhotoLoadingError: Error {
    case transferFailed(underlying: Error)
    case noData
    case decodingFailed
}

enum OCRError: Error {
    case noImages
    case recognitionFailed(underlying: Error)
    case noTextFound
}

enum AIServiceError: Error {
    case modelUnavailable
    case guardrailViolation
    case rateLimited
    case contextWindowExceeded
    case cancelled
    case unsupportedLanguage
    case decodingFailed
    case other(underlying: Error)

    init(from error: Error) {
        if let generationError = error as? LanguageModelSession.GenerationError {
            switch generationError {
            case .assetsUnavailable:
                self = .modelUnavailable
            case .rateLimited:
                self = .rateLimited
            case .exceededContextWindowSize:
                self = .contextWindowExceeded
            case .guardrailViolation:
                self = .guardrailViolation
            case .decodingFailure:
                self = .decodingFailed
            case .refusal:
                self = .guardrailViolation
            case .concurrentRequests:
                self = .rateLimited
            case .unsupportedGuide:
                self = .decodingFailed
            case .unsupportedLanguageOrLocale:
                self = .unsupportedLanguage
            @unknown default:
                self = .other(underlying: error)
            }
        } else if error is CancellationError {
            self = .cancelled
        } else {
            self = .other(underlying: error)
        }
    }
}

// MARK: - Unified Study Error

enum StudyError: LocalizedError {
    case photoLoading(PhotoLoadingError)
    case ocr(OCRError)
    case ai(AIServiceError)

    var errorDescription: String? {
        switch self {
        case .photoLoading(let error):
            switch error {
            case .transferFailed:
                return "Failed to load the selected photo."
            case .noData:
                return "The selected photo contains no data."
            case .decodingFailed:
                return "Could not decode the photo."
            }

        case .ocr(let error):
            switch error {
            case .noImages:
                return "No images to process."
            case .recognitionFailed:
                return "Text recognition failed. Try a clearer image."
            case .noTextFound:
                return "No text found in the selected images."
            }

        case .ai(let error):
            switch error {
            case .modelUnavailable:
                return "Apple Intelligence is temporarily unavailable. Please try again later."
            case .guardrailViolation:
                return "The request could not be processed due to content restrictions."
            case .rateLimited:
                return "Too many requests. Please wait a moment and try again."
            case .contextWindowExceeded:
                return "The text is too long for processing. Try selecting fewer pages."
            case .cancelled:
                return nil // Cancellation is silent
            case .unsupportedLanguage:
                return "The text language is not supported."
            case .decodingFailed:
                return "Failed to parse the AI response. Please try again."
            case .other:
                return "An unexpected error occurred. Please try again."
            }
        }
    }

    var isRetryable: Bool {
        switch self {
        case .photoLoading:
            return false
        case .ocr(let error):
            switch error {
            case .recognitionFailed: return true
            default: return false
            }
        case .ai(let error):
            switch error {
            case .rateLimited, .modelUnavailable, .decodingFailed, .other:
                return true
            default:
                return false
            }
        }
    }
}
