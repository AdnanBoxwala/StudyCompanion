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
// Phase 1: Make SwiftData models CloudKit-compatible ✅
//    - Added default values to all non-optional properties in Subject, Chapter, StudyEntry
//    - All relationships are optional on both sides
//    - No unique constraints
//    - Added schema migration V1 → V2 in SchemaVersions.swift
//
// Phase 2: Configure CloudKit sync ✅
//    - Enabled iCloud capability with CloudKit in Xcode (Signing & Capabilities)
//    - Enabled Background Modes → Remote notifications
//    - Created CloudKit container: iCloud.com.github.AdnanBoxwala.StudyCompanion
//    - Updated ModelConfiguration in StudyCompanionApp.swift with cloudKitDatabase: .private(...)
//
// Phase 3: Update Library UI for incomplete entries ✅
//    - StudyEntryDetailView: shows "Not yet generated" with Generate button (if AI available)
//      or info message (if AI unavailable) for missing summary/flashcards
//    - ChapterDetailView: shows "Text only" badge on entries missing both summary and flashcards
//    - LibraryEntryViewModel: handles AI generation on saved entries, updates SwiftData in place
//    - Enables cross-device workflow: save text on iPhone → generate AI on Mac
//
// Phase 4: Multi-platform support ✅
//    - Mac Catalyst (easiest): check "Mac" under Supported Destinations
//      - Document scanner won't be available on Mac (no camera)
//      - Photo import and AI processing will work
//      - Verify layout works on larger screens
//    - iPad: current iPhone app runs on iPad, verify layout
//    - Consider native macOS target later for better Mac UX
//
// Phase 5: Sync status indicator ✅
//    - SyncMonitor: observes NSPersistentCloudKitContainer.eventChangedNotification
//    - Exposes sync state (notStarted, syncing, synced, error, notAvailable)
//    - LibraryView toolbar: shows iCloud icon with color + pulse animation when syncing
//    - Injected via SwiftUI Environment from StudyCompanionApp
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

