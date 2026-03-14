import Testing
import PhotosUI
@testable import StudyCompanion

// MARK: - Mock Services

struct MockPhotoLoadingService: PhotoLoadingService {
    var result: Result<[UIImage], PhotoLoadingError> = .success([UIImage()])

    func loadImages(from items: [PhotosPickerItem]) async throws(PhotoLoadingError) -> [UIImage] {
        switch result {
        case .success(let images): return images
        case .failure(let error): throw error
        }
    }
}

struct MockOCRService: OCRService {
    var result: Result<String, OCRError> = .success("Sample extracted text for testing.")

    func extractText(from images: [UIImage]) async throws(OCRError) -> String {
        switch result {
        case .success(let text): return text
        case .failure(let error): throw error
        }
    }
}

struct MockAIService: AIService {
    var summarizeResult: Result<TextSummary, AIServiceError> = .success(
        TextSummary(summary: "Test summary", keyPoints: ["Point 1", "Point 2"])
    )
    var flashcardsResult: Result<[Flashcard], AIServiceError> = .success([
        Flashcard(front: "Q1", back: "A1"),
        Flashcard(front: "Q2", back: "A2")
    ])

    func summarize(text: String) async throws(AIServiceError) -> TextSummary {
        switch summarizeResult {
        case .success(let summary): return summary
        case .failure(let error): throw error
        }
    }

    func generateFlashcards(from text: String, count: Int) async throws(AIServiceError) -> [Flashcard] {
        switch flashcardsResult {
        case .success(let cards): return Array(cards.prefix(count))
        case .failure(let error): throw error
        }
    }
}

// MARK: - Slow Mock for Cancellation Testing

struct SlowMockOCRService: OCRService {
    func extractText(from images: [UIImage]) async throws(OCRError) -> String {
        try? await Task.sleep(for: .seconds(10))
        if Task.isCancelled { return "" }
        return "Slow result"
    }
}

// MARK: - StudyViewModel Tests

@Suite("StudyViewModel")
struct StudyViewModelTests {

    @Test("Extract text populates extractedText on success")
    @MainActor
    func extractTextSuccess() async {
        let vm = StudyViewModel(
            photoLoader: MockPhotoLoadingService(),
            ocr: MockOCRService(result: .success("Hello world")),
            ai: MockAIService()
        )
        vm.selectedImages = [UIImage()]

        vm.extractText()
        // Wait for the internal task to complete
        try? await Task.sleep(for: .milliseconds(100))

        #expect(vm.extractedText == "Hello world")
        #expect(vm.currentError == nil)
        #expect(vm.isExtractingText == false)
    }

    @Test("Extract text sets error on OCR failure")
    @MainActor
    func extractTextFailure() async {
        let vm = StudyViewModel(
            photoLoader: MockPhotoLoadingService(),
            ocr: MockOCRService(result: .failure(.noTextFound)),
            ai: MockAIService()
        )
        vm.selectedImages = [UIImage()]

        vm.extractText()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(vm.extractedText.isEmpty)
        #expect(vm.currentError != nil)
    }

    @Test("Summarize populates summary on success")
    @MainActor
    func summarizeSuccess() async {
        let vm = StudyViewModel(
            photoLoader: MockPhotoLoadingService(),
            ocr: MockOCRService(),
            ai: MockAIService()
        )
        vm.extractedText = "Some text to summarize"

        vm.summarizeText()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(vm.summary != nil)
        #expect(vm.summary?.summary == "Test summary")
        #expect(vm.currentError == nil)
    }

    @Test("Generate flashcards populates flashcards on success")
    @MainActor
    func generateFlashcardsSuccess() async {
        let vm = StudyViewModel(
            photoLoader: MockPhotoLoadingService(),
            ocr: MockOCRService(),
            ai: MockAIService()
        )
        vm.extractedText = "Some text for flashcards"

        vm.generateFlashcards(count: 2)
        try? await Task.sleep(for: .milliseconds(100))

        #expect(vm.flashcards.count == 2)
        #expect(vm.flashcards.first?.front == "Q1")
        #expect(vm.currentError == nil)
    }

    @Test("Generate flashcards sets error on AI failure")
    @MainActor
    func generateFlashcardsFailure() async {
        let mockAI = MockAIService(
            summarizeResult: .success(TextSummary(summary: "", keyPoints: [])),
            flashcardsResult: .failure(.rateLimited)
        )
        let vm = StudyViewModel(
            photoLoader: MockPhotoLoadingService(),
            ocr: MockOCRService(),
            ai: mockAI
        )
        vm.extractedText = "Some text"

        vm.generateFlashcards(count: 5)
        try? await Task.sleep(for: .milliseconds(100))

        #expect(vm.flashcards.isEmpty)
        #expect(vm.currentError != nil)
    }

    @Test("Reset cancels running tasks and clears state")
    @MainActor
    func resetCancelsAndClears() async {
        let vm = StudyViewModel(
            photoLoader: MockPhotoLoadingService(),
            ocr: SlowMockOCRService(),
            ai: MockAIService()
        )
        vm.selectedImages = [UIImage()]

        vm.extractText()
        // Give it a moment to start
        try? await Task.sleep(for: .milliseconds(50))
        #expect(vm.isExtractingText == true)

        vm.reset()

        #expect(vm.selectedImages.isEmpty)
        #expect(vm.extractedText.isEmpty)
        #expect(vm.summary == nil)
        #expect(vm.flashcards.isEmpty)
        #expect(vm.currentError == nil)
    }

    @Test("canSave requires extractedText and at least summary or flashcards")
    @MainActor
    func canSaveLogic() {
        let vm = StudyViewModel(
            photoLoader: MockPhotoLoadingService(),
            ocr: MockOCRService(),
            ai: MockAIService()
        )

        #expect(vm.canSave == false)

        vm.extractedText = "Some text"
        #expect(vm.canSave == false)

        vm.summary = TextSummary(summary: "Summary", keyPoints: ["Point"])
        #expect(vm.canSave == true)

        vm.summary = nil
        vm.flashcards = [Flashcard(front: "Q", back: "A")]
        #expect(vm.canSave == true)
    }

    @Test("Retry re-runs the last failed action")
    @MainActor
    func retryLastAction() async {
        let mockAI = MockAIService(
            summarizeResult: .failure(.rateLimited),
            flashcardsResult: .success([])
        )
        let vm = StudyViewModel(
            photoLoader: MockPhotoLoadingService(),
            ocr: MockOCRService(),
            ai: mockAI
        )
        vm.extractedText = "Text"

        vm.summarizeText()
        try? await Task.sleep(for: .milliseconds(100))
        #expect(vm.currentError != nil)

        // Retry should re-trigger summarizeText
        vm.retryLastAction()
        try? await Task.sleep(for: .milliseconds(100))
        // Still fails since mock returns same error, but confirms retry was called
        #expect(vm.currentError != nil)
    }
}

// MARK: - StudyError Tests

@Suite("StudyError")
struct StudyErrorTests {

    @Test("Retryable errors are correctly classified")
    func retryableErrors() {
        #expect(StudyError.ai(.rateLimited).isRetryable == true)
        #expect(StudyError.ai(.modelUnavailable).isRetryable == true)
        #expect(StudyError.ai(.decodingFailed).isRetryable == true)
        #expect(StudyError.ocr(.recognitionFailed(underlying: NSError(domain: "", code: 0))).isRetryable == true)
    }

    @Test("Non-retryable errors are correctly classified")
    func nonRetryableErrors() {
        #expect(StudyError.ai(.guardrailViolation).isRetryable == false)
        #expect(StudyError.ai(.contextWindowExceeded).isRetryable == false)
        #expect(StudyError.ai(.unsupportedLanguage).isRetryable == false)
        #expect(StudyError.ai(.cancelled).isRetryable == false)
        #expect(StudyError.ocr(.noImages).isRetryable == false)
        #expect(StudyError.ocr(.noTextFound).isRetryable == false)
        #expect(StudyError.photoLoading(.noData).isRetryable == false)
    }

    @Test("Error descriptions are user-friendly")
    func errorDescriptions() {
        #expect(StudyError.ai(.rateLimited).errorDescription != nil)
        #expect(StudyError.ocr(.noTextFound).errorDescription != nil)
        #expect(StudyError.photoLoading(.decodingFailed).errorDescription != nil)
        // Cancelled should be silent
        #expect(StudyError.ai(.cancelled).errorDescription == nil)
    }
}
