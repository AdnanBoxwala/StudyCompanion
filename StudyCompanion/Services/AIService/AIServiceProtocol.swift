import Foundation

protocol AIService: Sendable {
    func summarize(text: String) async throws(AIServiceError) -> TextSummary
    func generateFlashcards(from text: String, count: Int) async throws(AIServiceError) -> [Flashcard]
}
