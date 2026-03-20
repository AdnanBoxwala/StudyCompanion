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
//
// 3. Batch processing for larger documents.
//    - Remove or raise the 3-photo selection limit
//    - OCR: no changes needed — Vision handles any number of images
//    - Summarization: split extracted text into chunks (e.g. 3 pages each),
//      summarize each chunk, then run a final meta-summary pass to combine them
//    - Flashcards: generate cards per chunk, optionally deduplicate overlapping cards
//    - Add progress UI ("Processing batch 2 of 4...")
//    - Handle partial failure (if one batch fails, show results from successful batches)
//    - Chunk size needs experimentation based on FoundationModels context window limit

// MARK: - iCloud Sync & Multi-Device Support
//
// Goal: Scan on iPhone (even without Apple Intelligence), process on Mac/iPad
// with Apple Intelligence, keep everything in sync via iCloud.
//
// Phase 1: Make SwiftData models CloudKit-compatible
//    - Add default values to all non-optional properties in Subject, Chapter, StudyEntry
//      (CloudKit requires defaults since records can arrive in any order)
//    - Ensure all relationships are optional on both sides
//    - No unique constraints allowed
//    - Add schema migration V1 → V2 in SchemaVersions.swift
//
// Phase 2: Configure CloudKit sync
//    - Enable iCloud capability with CloudKit in Xcode (Signing & Capabilities)
//    - Enable Background Modes → Remote notifications
//    - Create/select a CloudKit container (e.g. iCloud.com.github.AdnanBoxwala.StudyCompanion)
//    - Update ModelConfiguration in StudyCompanionApp.swift:
//      ModelConfiguration(cloudKitDatabase: .private("iCloud.com.github.AdnanBoxwala.StudyCompanion"))
//
// Phase 3: Update Library UI for incomplete entries
//    - StudyEntryDetailView: when summary/flashcards are nil, show "Not yet generated"
//      with a Generate button (if AI is available on this device) or an info message (if not)
//    - ChapterDetailView: show a badge/subtitle on entries that are text-only ("Text only")
//    - This enables the cross-device workflow: save text on iPhone → generate AI on Mac
//
// Phase 4: Multi-platform support
//    - Mac Catalyst (easiest): check "Mac" under Supported Destinations
//      - Document scanner won't be available on Mac (no camera)
//      - Photo import and AI processing will work
//      - Verify layout works on larger screens
//    - iPad: current iPhone app runs on iPad, verify layout
//    - Consider native macOS target later for better Mac UX
//
// Phase 5: Sync status indicator
//    - Show sync status in the UI (syncing, up to date, error)
//    - Handle merge conflicts gracefully
//    - Consider using NSPersistentCloudKitContainer event notifications
//
// Sync workflow:
//   1. iPhone: scan pages → extract text (Vision works on all devices) → save
//   2. iCloud syncs StudyEntry (text only, no summary/flashcards) to Mac
//   3. Mac: open entry from Library → tap Summarize / Generate Flashcards
//   4. iCloud syncs updated entry (with summary + flashcards) back to iPhone
//   5. iPhone: open Library → see complete study entry
//
// Storage: only sync text data (extracted text, summaries, flashcards, metadata).
// Do NOT sync scanned images — they are large and not needed for AI processing.
