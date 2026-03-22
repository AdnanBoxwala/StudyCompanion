import SwiftData
import SwiftUI
import Testing
@testable import StudyCompanion

// MARK: - Test Helper

/// Yields to the main run loop repeatedly to allow internal Tasks to complete.
@MainActor
private func yieldForTasks() async {
    for _ in 0..<30 {
        await Task.yield()
    }
}

// MARK: - Test Data Factory

@MainActor
private func makeTestContext() throws -> (ModelContainer, ModelContext, StudyEntry) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: Subject.self, Chapter.self, StudyEntry.self,
        configurations: config
    )
    let context = container.mainContext

    let subject = Subject(name: "Math")
    context.insert(subject)
    let chapter = Chapter(name: "Algebra", subject: subject)
    context.insert(chapter)
    let entry = StudyEntry(
        topicName: "Quadratics",
        extractedText: "A quadratic equation is a polynomial equation of degree two.",
        chapter: chapter
    )
    context.insert(entry)

    return (container, context, entry)
}

// MARK: - LibraryEntryViewModel Tests

@Suite("LibraryEntryViewModel")
struct LibraryEntryViewModelTests {

    // MARK: - Summary Generation

    @Test("Generate summary updates entry's summaryText and keyPoints")
    @MainActor
    func generateSummarySuccess() async throws {
        let (container, context, entry) = try makeTestContext()
        _ = container

        #expect(entry.summaryText == nil)
        #expect(entry.keyPoints == nil)

        let vm = LibraryEntryViewModel(entry: entry, modelContext: context, ai: MockAIService())
        vm.generateSummary()
        await yieldForTasks()

        #expect(entry.summaryText == "Test summary")
        #expect(entry.keyPoints == ["Point 1", "Point 2"])
        #expect(vm.isSummarizing == false)
        #expect(vm.currentError == nil)
    }

    @Test("Generate summary sets error on AI failure")
    @MainActor
    func generateSummaryFailure() async throws {
        let (container, context, entry) = try makeTestContext()
        _ = container

        let mockAI = MockAIService(
            summarizeResult: .failure(.rateLimited),
            flashcardsResult: .success([])
        )
        let vm = LibraryEntryViewModel(entry: entry, modelContext: context, ai: mockAI)
        vm.generateSummary()
        await yieldForTasks()

        #expect(entry.summaryText == nil)
        #expect(vm.isSummarizing == false)
        #expect(vm.currentError != nil)
    }

    @Test("Generate summary skips when extractedText is empty")
    @MainActor
    func generateSummaryEmptyText() async throws {
        let (container, context, entry) = try makeTestContext()
        _ = container
        entry.extractedText = ""

        let vm = LibraryEntryViewModel(entry: entry, modelContext: context, ai: MockAIService())
        vm.generateSummary()
        await yieldForTasks()

        #expect(entry.summaryText == nil)
        #expect(vm.currentError == nil)
    }

    @Test("Generate summary silently ignores cancelled error")
    @MainActor
    func generateSummaryCancelled() async throws {
        let (container, context, entry) = try makeTestContext()
        _ = container

        let mockAI = MockAIService(
            summarizeResult: .failure(.cancelled),
            flashcardsResult: .success([])
        )
        let vm = LibraryEntryViewModel(entry: entry, modelContext: context, ai: mockAI)
        vm.generateSummary()
        await yieldForTasks()

        #expect(entry.summaryText == nil)
        #expect(vm.currentError == nil)
    }

    // MARK: - Flashcard Generation

    @Test("Generate flashcards updates entry's storedFlashcards")
    @MainActor
    func generateFlashcardsSuccess() async throws {
        let (container, context, entry) = try makeTestContext()
        _ = container

        #expect(entry.storedFlashcards == nil)

        let vm = LibraryEntryViewModel(entry: entry, modelContext: context, ai: MockAIService())
        vm.generateFlashcards(count: 2)
        await yieldForTasks()

        #expect(entry.storedFlashcards?.count == 2)
        #expect(entry.storedFlashcards?.first?.front == "Q1")
        #expect(entry.storedFlashcards?.first?.back == "A1")
        #expect(vm.isGeneratingFlashcards == false)
        #expect(vm.currentError == nil)
    }

    @Test("Generate flashcards sets error on AI failure")
    @MainActor
    func generateFlashcardsFailure() async throws {
        let (container, context, entry) = try makeTestContext()
        _ = container

        let mockAI = MockAIService(
            summarizeResult: .success(TextSummary(summary: "", keyPoints: [])),
            flashcardsResult: .failure(.contextWindowExceeded)
        )
        let vm = LibraryEntryViewModel(entry: entry, modelContext: context, ai: mockAI)
        vm.generateFlashcards(count: 5)
        await yieldForTasks()

        #expect(entry.storedFlashcards == nil)
        #expect(vm.isGeneratingFlashcards == false)
        #expect(vm.currentError != nil)
    }

    @Test("Generate flashcards skips when extractedText is empty")
    @MainActor
    func generateFlashcardsEmptyText() async throws {
        let (container, context, entry) = try makeTestContext()
        _ = container
        entry.extractedText = ""

        let vm = LibraryEntryViewModel(entry: entry, modelContext: context, ai: MockAIService())
        vm.generateFlashcards(count: 5)
        await yieldForTasks()

        #expect(entry.storedFlashcards == nil)
        #expect(vm.currentError == nil)
    }

    @Test("Generate flashcards silently ignores cancelled error")
    @MainActor
    func generateFlashcardsCancelled() async throws {
        let (container, context, entry) = try makeTestContext()
        _ = container

        let mockAI = MockAIService(
            summarizeResult: .success(TextSummary(summary: "", keyPoints: [])),
            flashcardsResult: .failure(.cancelled)
        )
        let vm = LibraryEntryViewModel(entry: entry, modelContext: context, ai: mockAI)
        vm.generateFlashcards(count: 5)
        await yieldForTasks()

        #expect(entry.storedFlashcards == nil)
        #expect(vm.currentError == nil)
    }

    // MARK: - Properties

    @Test("isAIAvailable and modelAvailability do not crash")
    @MainActor
    func aiAvailabilityProperties() throws {
        let (container, context, entry) = try makeTestContext()
        _ = container

        let vm = LibraryEntryViewModel(entry: entry, modelContext: context, ai: MockAIService())
        // Just verify these don't crash — actual availability depends on hardware
        _ = vm.isAIAvailable
        _ = vm.modelAvailability
    }

    @Test("Default AI service is AppleIntelligenceService when none provided")
    @MainActor
    func defaultAIService() throws {
        let (container, context, entry) = try makeTestContext()
        _ = container

        // Should not crash — uses default AppleIntelligenceService
        let vm = LibraryEntryViewModel(entry: entry, modelContext: context)
        #expect(vm.currentError == nil)
    }

    // MARK: - Retry

    @Test("retryLastAction retries summary generation after failure")
    @MainActor
    func retryLastActionSummary() async throws {
        let (container, context, entry) = try makeTestContext()
        _ = container

        let mockAI = MockAIService(
            summarizeResult: .failure(.rateLimited),
            flashcardsResult: .success([])
        )
        let vm = LibraryEntryViewModel(entry: entry, modelContext: context, ai: mockAI)

        vm.generateSummary()
        await yieldForTasks()
        #expect(vm.currentError != nil)

        // Retry should re-trigger generateSummary — same mock so still fails
        vm.retryLastAction()
        await yieldForTasks()
        #expect(vm.currentError != nil)
        #expect(entry.summaryText == nil)
    }

    @Test("retryLastAction retries flashcard generation after failure")
    @MainActor
    func retryLastActionFlashcards() async throws {
        let (container, context, entry) = try makeTestContext()
        _ = container

        let mockAI = MockAIService(
            summarizeResult: .success(TextSummary(summary: "", keyPoints: [])),
            flashcardsResult: .failure(.contextWindowExceeded)
        )
        let vm = LibraryEntryViewModel(entry: entry, modelContext: context, ai: mockAI)

        vm.generateFlashcards(count: 5)
        await yieldForTasks()
        #expect(vm.currentError != nil)

        // Retry should re-trigger generateFlashcards with same count
        vm.retryLastAction()
        await yieldForTasks()
        #expect(vm.currentError != nil)
        #expect(entry.storedFlashcards == nil)
    }

    // MARK: - Presentable Error

    @Test("presentableError returns error for non-cancelled errors")
    @MainActor
    func presentableErrorNonCancelled() async throws {
        let (container, context, entry) = try makeTestContext()
        _ = container

        let mockAI = MockAIService(
            summarizeResult: .failure(.rateLimited),
            flashcardsResult: .success([])
        )
        let vm = LibraryEntryViewModel(entry: entry, modelContext: context, ai: mockAI)

        vm.generateSummary()
        await yieldForTasks()

        #expect(vm.currentError != nil)
        #expect(vm.presentableError != nil)
        #expect(vm.presentableError?.errorDescription != nil)
    }

    @Test("presentableError returns nil for cancelled errors")
    @MainActor
    func presentableErrorCancelled() throws {
        let (container, context, entry) = try makeTestContext()
        _ = container

        let vm = LibraryEntryViewModel(entry: entry, modelContext: context, ai: MockAIService())

        // Manually set a cancelled error
        vm.currentError = .ai(.cancelled)

        #expect(vm.currentError != nil)
        #expect(vm.presentableError == nil)
    }

    @Test("presentableError returns nil when no error")
    @MainActor
    func presentableErrorNil() throws {
        let (container, context, entry) = try makeTestContext()
        _ = container

        let vm = LibraryEntryViewModel(entry: entry, modelContext: context, ai: MockAIService())

        #expect(vm.currentError == nil)
        #expect(vm.presentableError == nil)
    }
}
