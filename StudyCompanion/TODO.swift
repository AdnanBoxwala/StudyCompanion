// MARK: - Future Improvements
//
// 1. Consolidate FlashcardData and Flashcard into a single type.
//    - Remove FlashcardData struct
//    - Use Flashcard (with UUID) for both in-memory UI and SwiftData storage
//    - Remove the mapping in StudyViewModel.save() and FlashcardListView.init(storedFlashcards:)
//    - Gives stable identity across sessions, needed for future features like progress tracking
//    - Note: will require a SwiftData migration if done after shipping
//
// 2. Cloud API fallback for non-Apple Intelligence devices.
//    - Add a CloudAIService conforming to AIService protocol
//    - Use OpenAI, Anthropic, or similar API for summarization and flashcard generation
//    - Detect device capability via SystemLanguageModel.default.availability
//    - If .unavailable(.deviceNotEligible), offer cloud-based processing as alternative
//    - Requires API key management (e.g. Keychain storage)
//    - Consider a settings screen for users to enter their own API keys
//    - The service protocol extraction (already done) makes this a drop-in replacement
