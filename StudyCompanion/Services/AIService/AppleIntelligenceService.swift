import FoundationModels

struct AppleIntelligenceService: AIService {
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
