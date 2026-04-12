// MARK: - Pre-Release Checklist (do these before first App Store submission)
//
// 1. Replace ErrorBannerView with alert-based error presentation. ✅
//    - Migrated to .alert(isPresented:presenting:) modifier
//    - "Retry" button for retryable errors, "OK" for non-retryable
//    - Updated StudyView and StudyEntryDetailView
//    - Added retryLastAction() to LibraryEntryViewModel
//    - Deleted ErrorBannerView.swift
//
// 2. Privacy policy URL. ✅
//    - Required by App Store Connect — submission will be rejected without one
//    - Host on GitHub Pages or a simple static site
//    - Describe: on-device OCR (Vision), on-device AI (Apple Intelligence),
//      iCloud sync (private database, only user's own data), no third-party analytics
//    - No user data leaves the device except via iCloud (Apple's infrastructure)
//
// 3. App Store metadata. ✅
//    - App description and keywords for App Store listing
//    - Screenshots: minimum 6.7" iPhone (iPhone 15 Pro Max) and 6.5" iPhone (iPhone 11 Pro Max)
//    - Category: Education
//    - Support URL (can be a GitHub repo or simple landing page)
//
// 4. TestFlight validation.
//    - Install via TestFlight on a clean device (or at least delete local data first)
//    - Full flow test: scan → OCR → summarize → flashcards → save → verify in Library
//    - Test empty states: Library with no data, no images selected, no extracted text
//    - Test iCloud sync: save on one device, verify it appears on another
//    - Test error states: deny camera permission, try AI on non-Apple-Intelligence device
//    - Test on Mac via TestFlight (Designed for iPad)
//
// 5. Verify privacy descriptions in Info.plist.
//    - NSCameraUsageDescription must be present (for document scanner)
//    - Confirm wording is clear and user-friendly
//    - App Store Review will reject if missing or vague

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
//    - Also applies to cloud OCR (Mathpix, Google Cloud Vision) for math-aware text extraction
//    - The service protocol extraction (already done) makes this a drop-in replacement
//
//    API key strategy (start with Option A, add Option B later if demand exists):
//
//    Option A: User provides their own API key (recommended first)
//      - Settings screen where user pastes their API key (Mathpix / OpenAI / etc.)
//      - Store key in Keychain (NOT UserDefaults — keys are secrets)
//      - App calls the third-party API directly from device using user's key
//      - Zero infrastructure cost to developer
//      - No IAP needed — user pays the API provider directly
//      - Downside: high friction for non-technical users (students)
//      - Best for: power users, STEM students who already have API accounts
//      - Put behind "Advanced" / "STEM Mode" setting
//
//    Option B: Developer-hosted proxy service (future, if demand validated)
//      - Backend server (AWS Lambda / Cloudflare Workers / etc.) holds API keys
//      - App authenticates via Sign in with Apple → server validates → proxies to API
//      - NEVER ship API keys in the app binary — extractable in minutes
//      - Charge users via IAP (subscription or credit packs)
//      - Apple takes 15-30% of IAP revenue — factor into pricing
//      - Need usage limits per user to prevent runaway API costs
//      - Need uptime monitoring, auth, abuse prevention
//      - GDPR consideration: users send textbook photos through your server
//
//    Privacy (both options):
//      - Disclose that images/text are sent to third-party APIs in privacy policy
//      - Show a one-time consent prompt before the first cloud API call
//      - Especially important for student users who may be minors
//
// 3. (Completed — see Pre-Release Checklist #1)
//
// 4. Redesign StudyEntryDetailView with a richer layout. ✅
//    - Replaced List with ScrollView + material cards (RoundedRectangle + .regularMaterial)
//    - Each section (Extracted Text, Summary, Flashcards) is a styled card with tinted icon
//    - Extracted text shows 3-line preview snippet
//    - Summary shows inline preview + key point capsule chips (FlowLayout)
//    - Flashcards show count badge + mini preview of first card's front text
//    - Generate buttons styled as prominent tinted cards with sparkles icon
//    - Animated transitions: .blurReplace between generate/content states,
//      .smooth on summary/flashcard appearance, .numericText on flashcard count,
//      .easeInOut on progress indicators
//
// 5. Batch processing for larger documents.
//    - Remove or raise the 3-photo selection limit
//    - OCR: no changes needed — Vision handles any number of images
//    - Summarization: split extracted text into chunks (e.g. 3 pages each),
//      summarize each chunk, then run a final meta-summary pass to combine them
//    - Flashcards: generate cards per chunk, optionally deduplicate overlapping cards
//    - Add progress UI ("Processing batch 2 of 4...")
//    - Handle partial failure (if one batch fails, show results from successful batches)
//    - Chunk size needs experimentation based on FoundationModels context window limit
//
// 6. Known limitation: OCR and mathematical/scientific notation.
//    - Apple's VNRecognizeTextRequest is optimized for natural language text
//    - Works well: basic operators (+, −, =), simple inline formulas (F=ma, E=mc^2, H2O)
//    - Unreliable: superscripts/subscripts (x² → "x2"), Greek letters (α, θ)
//    - Fails: integrals (∫), summation (Σ), fractions, matrices, complex LaTeX-style notation
//    - Chemical structures and reaction diagrams are not recognized at all
//    - The AI model (FoundationModels) can reason about equations IF the OCR produces
//      coherent text — the bottleneck is OCR, not the AI
//    - App is most effective for text-heavy subjects (biology, history, law, economics)
//    - Still usable for STEM where explanatory paragraphs carry the core meaning
//    - No code-level fix — this is a fundamental Vision framework limitation
//    - Future options:
//      a) Cloud OCR API (recommended): Mathpix or Google Cloud Vision — math-aware,
//         returns LaTeX output, no model bundling needed. Pairs with TODO #2 (Cloud API
//         fallback). User setting: Apple Vision (free/on-device) vs Cloud OCR (API key).
//      b) On-device open-source models: Nougat (Meta, ~350MB, academic papers → LaTeX),
//         TrOCR (Microsoft, ~330MB, transformer OCR), Texify (math → LaTeX).
//         Would need Core ML conversion, optional download (too large to bundle),
//         custom preprocessing/decoding pipeline. High integration complexity.
//      c) Apple may add math-aware OCR in a future Vision framework update
//
// 7. Support other languages
//    - Can the model generate summaries in all langauges?
//    - Should the prompt be altered?


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

// MARK: - Quiz Feature (Knowledge Testing)
//
// Goal: Let users test their understanding of a topic via AI-generated MCQs,
// track scores over time, and surface topics that need revision.
//
// Design decisions:
//   - Source material: extracted text (full textbook content), NOT limited to flashcards
//   - Quiz questions are regenerated each attempt (not stored) — keeps quizzes fresh
//   - Only scores are persisted to SwiftData, not question content
//   - Each question includes a sourceExcerpt field (the sentence from extracted text
//     that supports the correct answer) — shown after the user answers for verification
//   - "Flag this question" button per question — flagged questions don't count toward score
//   - Disclaimer in UI: "Questions are AI-generated — verify answers against your textbook"
//
// Scoring thresholds:
//   - Below 60%  → Critical (red badge)
//   - 60–80%     → Needs Review (orange badge)
//   - Above 80%  → Confident (green badge)
//   - Not attempted → no badge
//
// Phase 1: Data Models
//   - QuizResult (SwiftData model, linked to StudyEntry):
//     - date: Date
//     - score: Int (number correct)
//     - totalQuestions: Int
//     - flaggedCount: Int (questions the user flagged as incorrect)
//     - studyEntry: StudyEntry? (relationship)
//   - QuizQuestion (Codable struct, in-memory only, NOT stored):
//     - question: String
//     - correctAnswer: String
//     - distractors: [String] (3 wrong answers)
//     - sourceExcerpt: String (grounding reference from extracted text)
//   - QuizStatus enum: .critical, .needsReview, .confident, .notAttempted
//   - Computed properties on StudyEntry: latestQuizScore, quizStatus
//   - Make QuizResult CloudKit-compatible (optional relationship, defaults)
//
// Phase 2: Quiz Generation Service
//   - Define QuizService protocol:
//     func generateQuiz(from text: String, count: Int) async throws -> [QuizQuestion]
//   - Implement AppleIntelligenceQuizService using FoundationModels
//   - Use @Generable structured output schema for reliable parsing
//   - Prompt: generate MCQs from the provided text, each with 1 correct answer,
//     3 plausible distractors, and a sourceExcerpt (exact quote from the text)
//   - Validate output: exactly 4 options per question, correct answer is among them
//   - Minimum requirement: extracted text must be non-empty to generate quiz
//   - Add to AIService protocol or create separate QuizService protocol
//
// Phase 3: Quiz UI
//   - New "Quiz" tab in ContentView (3rd tab)
//   - Quiz setup screen:
//     - Pick subject → chapter → topic (only topics with extracted text)
//     - Question count stepper (5–15)
//     - "Start Quiz" button (disabled if AI unavailable)
//   - Quiz view (one question at a time):
//     - Question text at top
//     - 4 answer buttons (shuffled order each time)
//     - On selection: highlight green (correct) or red (wrong), show sourceExcerpt
//     - "Flag this question" button — marks it as AI error, won't count toward score
//     - "Next" button to advance
//     - Progress bar: "Question 3 of 10"
//   - Results screen:
//     - Score with percentage and status badge (critical/needsReview/confident)
//     - Per-question breakdown: correct/wrong/flagged with source excerpts
//     - "Review Mistakes" button → navigates to flashcards for the topic
//     - "Retake Quiz" button → regenerates fresh questions
//   - QuizViewModel: manages generation, current question index, answers, scoring
//
// Phase 4: Score Persistence & Critical Topic Tracking
//   - Save QuizResult to SwiftData after quiz completion
//   - Add computed properties on StudyEntry:
//     - latestQuizResult: QuizResult? (most recent by date)
//     - quizStatus: QuizStatus (based on latest score percentage)
//   - Show status badges in Library views:
//     - ChapterDetailView: colored dot or badge next to topic name
//     - SubjectDetailView: aggregate status (worst topic status in chapter)
//   - Quiz tab home screen: "Needs Attention" section showing critical topics
//   - Quiz history per topic: list of past attempts with dates and scores
//
// Phase 5: Polish
//   - Shuffle answer positions each attempt
//   - Animate transitions between questions (slide or fade)
//   - Handle edge cases: very short extracted text, AI generation failure mid-quiz
//   - Add quiz score trend (improving / declining) based on last 3 attempts
//   - Consider "Review Mistakes" linking directly to relevant flashcard pairs

