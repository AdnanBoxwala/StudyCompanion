import Foundation

// TODO: Implement cloud API fallback for non-Apple Intelligence devices.
// - Use OpenAI, Anthropic, or similar API for summarization and flashcard generation
// - Detect device capability via SystemLanguageModel.default.availability
// - If .unavailable(.deviceNotEligible), offer cloud-based processing as alternative
// - Requires API key management (e.g. Keychain storage)
// - Consider a settings screen for users to enter their own API keys
// - The AIService protocol makes this a drop-in replacement

// struct CloudAIService: AIService {
//     func summarize(text: String) async throws(AIServiceError) -> TextSummary { }
//     func generateFlashcards(from text: String, count: Int) async throws(AIServiceError) -> [Flashcard] { }
// }
