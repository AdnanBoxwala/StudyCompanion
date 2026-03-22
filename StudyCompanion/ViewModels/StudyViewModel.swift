import FoundationModels
import PhotosUI
import SwiftData
import SwiftUI

@Observable
@MainActor
final class StudyViewModel {
    // MARK: - Services

    private let photoLoader: any PhotoLoadingService
    private let ocr: any OCRService
    private let ai: any AIService

    init(
        photoLoader: (any PhotoLoadingService)? = nil,
        ocr: (any OCRService)? = nil,
        ai: (any AIService)? = nil
    ) {
        self.photoLoader = photoLoader ?? ApplePhotoLoadingService()
        self.ocr = ocr ?? AppleOCRService()
        self.ai = ai ?? AppleIntelligenceService()
    }

    // MARK: - Photo Selection
    var selectedPhotoItems: [PhotosPickerItem] = []
    var selectedImages: [UIImage] = []

    // MARK: - Extracted Text
    var extractedText: String = ""
    var isExtractingText = false

    // MARK: - Summary
    var summary: TextSummary?
    var isSummarizing = false

    // MARK: - Flashcards
    var flashcards: [Flashcard] = []
    var isGeneratingFlashcards = false

    // MARK: - General State
    var currentError: StudyError?

    /// Returns the current error only if it should be presented to the user.
    /// Silent errors (e.g. cancelled) return nil.
    var presentableError: StudyError? {
        guard let error = currentError, error.errorDescription != nil else { return nil }
        return error
    }
    var modelAvailability: SystemLanguageModel.Availability {
        SystemLanguageModel.default.availability
    }

    // MARK: - Task Management

    private var loadingTask: Task<Void, Never>?
    private var extractionTask: Task<Void, Never>?
    private var summarizationTask: Task<Void, Never>?
    private var flashcardTask: Task<Void, Never>?

    /// Tracks the last failed action for retry support.
    private var lastAction: LastAction?

    private enum LastAction {
        case extract
        case summarize
        case generateFlashcards(count: Int)
    }

    // MARK: - Scanned Images

    func addScannedImages(_ images: [UIImage]) {
        selectedImages = images
        selectedPhotoItems = []
        extractedText = ""
        summary = nil
        flashcards = []
        currentError = nil
    }

    // MARK: - Photo Loading

    func loadImages() {
        loadingTask?.cancel()
        loadingTask = Task {
            guard !selectedPhotoItems.isEmpty else { return }
            do {
                let images = try await photoLoader.loadImages(from: selectedPhotoItems)
                guard !Task.isCancelled else { return }
                selectedImages = images
                extractedText = ""
                summary = nil
                flashcards = []
                currentError = nil
            } catch let error as PhotoLoadingError {
                guard !Task.isCancelled else { return }
                currentError = .photoLoading(error)
            } catch {
                guard !Task.isCancelled else { return }
            }
        }
    }

    // MARK: - OCR Text Extraction

    func extractText() {
        extractionTask?.cancel()
        lastAction = .extract
        extractionTask = Task {
            isExtractingText = true
            defer { isExtractingText = false }
            currentError = nil

            do {
                let text = try await ocr.extractText(from: selectedImages)
                guard !Task.isCancelled else { return }
                extractedText = text
            } catch let error as OCRError {
                guard !Task.isCancelled else { return }
                currentError = .ocr(error)
            } catch {
                guard !Task.isCancelled else { return }
            }
        }
    }

    // MARK: - Summarize with Apple Intelligence

    func summarizeText() {
        summarizationTask?.cancel()
        lastAction = .summarize
        summarizationTask = Task {
            guard !extractedText.isEmpty else { return }
            isSummarizing = true
            defer { isSummarizing = false }
            currentError = nil

            do {
                let result = try await ai.summarize(text: extractedText)
                guard !Task.isCancelled else { return }
                summary = result
            } catch let error as AIServiceError {
                guard !Task.isCancelled else { return }
                if case .cancelled = error { return }
                currentError = .ai(error)
            } catch {
                guard !Task.isCancelled else { return }
            }
        }
    }

    // MARK: - Generate Flashcards with Apple Intelligence

    func generateFlashcards(count: Int) {
        flashcardTask?.cancel()
        lastAction = .generateFlashcards(count: count)
        flashcardTask = Task {
            guard !extractedText.isEmpty else { return }
            isGeneratingFlashcards = true
            defer { isGeneratingFlashcards = false }
            currentError = nil

            do {
                let cards = try await ai.generateFlashcards(from: extractedText, count: count)
                guard !Task.isCancelled else { return }
                flashcards = cards
            } catch let error as AIServiceError {
                guard !Task.isCancelled else { return }
                if case .cancelled = error { return }
                currentError = .ai(error)
            } catch {
                guard !Task.isCancelled else { return }
            }
        }
    }

    // MARK: - Retry

    func retryLastAction() {
        guard let action = lastAction else { return }
        switch action {
        case .extract:
            extractText()
        case .summarize:
            summarizeText()
        case .generateFlashcards(let count):
            generateFlashcards(count: count)
        }
    }

    // MARK: - Saving

    var canSave: Bool {
        !extractedText.isEmpty
    }

    func save(subjectName: String, chapterName: String, topicName: String, modelContext: ModelContext) {
        // Find or create subject
        let subjectPredicate = #Predicate<Subject> { $0.name == subjectName }
        let subjectDescriptor = FetchDescriptor<Subject>(predicate: subjectPredicate)
        let subject: Subject
        if let existing = try? modelContext.fetch(subjectDescriptor).first {
            subject = existing
        } else {
            subject = Subject(name: subjectName)
            modelContext.insert(subject)
        }

        // Find or create chapter under that subject
        let chapter: Chapter
        if let existing = (subject.chapters ?? []).first(where: { $0.name == chapterName }) {
            chapter = existing
        } else {
            chapter = Chapter(name: chapterName, subject: subject)
            modelContext.insert(chapter)
        }

        // Build flashcard data
        let flashcardData: [FlashcardData]? = flashcards.isEmpty ? nil : flashcards.map {
            FlashcardData(front: $0.front, back: $0.back)
        }

        // Create entry
        let entry = StudyEntry(
            topicName: topicName,
            extractedText: extractedText,
            summaryText: summary?.summary,
            keyPoints: summary?.keyPoints,
            storedFlashcards: flashcardData,
            chapter: chapter
        )
        modelContext.insert(entry)
    }

    // MARK: - Reset

    func reset() {
        loadingTask?.cancel()
        extractionTask?.cancel()
        summarizationTask?.cancel()
        flashcardTask?.cancel()

        selectedPhotoItems = []
        selectedImages = []
        extractedText = ""
        summary = nil
        flashcards = []
        currentError = nil
        lastAction = nil
    }
}
