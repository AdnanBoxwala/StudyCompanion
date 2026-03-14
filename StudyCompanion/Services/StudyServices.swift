import PhotosUI
import SwiftUI

// MARK: - Service Protocols

protocol PhotoLoadingService: Sendable {
    func loadImages(from items: [PhotosPickerItem]) async throws(PhotoLoadingError) -> [UIImage]
}

protocol OCRService: Sendable {
    func extractText(from images: [UIImage]) async throws(OCRError) -> String
}

protocol AIService: Sendable {
    func summarize(text: String) async throws(AIServiceError) -> TextSummary
    func generateFlashcards(from text: String, count: Int) async throws(AIServiceError) -> [Flashcard]
}
