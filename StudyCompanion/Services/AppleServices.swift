import FoundationModels
import PhotosUI
import SwiftUI
import Vision

// MARK: - Photo Loading

struct ApplePhotoLoadingService: PhotoLoadingService {
    func loadImages(from items: [PhotosPickerItem]) async throws(PhotoLoadingError) -> [UIImage] {
        var images: [UIImage] = []
        for item in items {
            guard !Task.isCancelled else { return images }
            let data: Data?
            do {
                data = try await item.loadTransferable(type: Data.self)
            } catch {
                throw .transferFailed(underlying: error)
            }
            guard let data else { throw .noData }
            guard let image = UIImage(data: data) else { throw .decodingFailed }
            images.append(image)
        }
        return images
    }
}

// MARK: - OCR

struct AppleOCRService: OCRService {
    func extractText(from images: [UIImage]) async throws(OCRError) -> String {
        guard !images.isEmpty else { throw .noImages }

        var allPageTexts: [String] = []

        for image in images {
            guard !Task.isCancelled else { break }
            guard let cgImage = image.cgImage else { continue }

            do {
                var request = RecognizeTextRequest()
                request.recognitionLevel = .accurate
                let observations = try await request.perform(on: cgImage)
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                let pageText = recognizedStrings.joined(separator: "\n")
                if !pageText.isEmpty {
                    allPageTexts.append(pageText)
                }
            } catch {
                throw .recognitionFailed(underlying: error)
            }
        }

        let result = allPageTexts.joined(separator: "\n\n")
        guard !result.isEmpty else { throw .noTextFound }
        return result
    }
}

// MARK: - AI Service

struct AppleAIService: AIService {
    func summarize(text: String) async throws(AIServiceError) -> TextSummary {
        do {
            try Task.checkCancellation()
            let session = LanguageModelSession(
                instructions: "You are a study assistant. Summarize the provided text clearly and concisely for a student."
            )
            let response = try await session.respond(
                to: "Summarize the following text:\n\n\(text)",
                generating: TextSummary.self
            )
            return response.content
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError(from: error)
        }
    }

    func generateFlashcards(from text: String, count: Int) async throws(AIServiceError) -> [Flashcard] {
        do {
            try Task.checkCancellation()
            let session = LanguageModelSession(
                instructions: "You are a study assistant. Create flashcards from the provided text. Each flashcard should have a clear question or key term on the front, and a concise answer or definition on the back."
            )
            let response = try await session.respond(
                to: "Create exactly \(count) flashcards from the following text:\n\n\(text)",
                generating: FlashcardSet.self
            )
            return response.content.cards.map { generated in
                Flashcard(front: generated.front, back: generated.back)
            }
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError(from: error)
        }
    }
}
