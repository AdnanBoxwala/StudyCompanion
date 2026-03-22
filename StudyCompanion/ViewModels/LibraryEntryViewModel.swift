import FoundationModels
import SwiftData
import SwiftUI

@Observable
@MainActor
final class LibraryEntryViewModel {
    private let ai: any AIService
    private let entry: StudyEntry
    private let modelContext: ModelContext

    // MARK: - State

    var isSummarizing = false
    var isGeneratingFlashcards = false
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

    var isAIAvailable: Bool {
        modelAvailability == .available
    }

    // MARK: - Task Management

    private var summarizationTask: Task<Void, Never>?
    private var flashcardTask: Task<Void, Never>?

    /// Tracks the last failed action for retry support.
    private var lastAction: LastAction?

    private enum LastAction {
        case summarize
        case generateFlashcards(count: Int)
    }

    init(entry: StudyEntry, modelContext: ModelContext, ai: (any AIService)? = nil) {
        self.entry = entry
        self.modelContext = modelContext
        self.ai = ai ?? AppleIntelligenceService()
    }

    // MARK: - Generate Summary

    func generateSummary() {
        summarizationTask?.cancel()
        lastAction = .summarize
        summarizationTask = Task {
            guard !entry.extractedText.isEmpty else { return }
            isSummarizing = true
            defer { isSummarizing = false }
            currentError = nil

            do {
                let result = try await ai.summarize(text: entry.extractedText)
                guard !Task.isCancelled else { return }
                entry.summaryText = result.summary
                entry.keyPoints = result.keyPoints
            } catch let error as AIServiceError {
                guard !Task.isCancelled else { return }
                if case .cancelled = error { return }
                currentError = .ai(error)
            } catch {
                guard !Task.isCancelled else { return }
            }
        }
    }

    // MARK: - Generate Flashcards

    func generateFlashcards(count: Int) {
        flashcardTask?.cancel()
        lastAction = .generateFlashcards(count: count)
        flashcardTask = Task {
            guard !entry.extractedText.isEmpty else { return }
            isGeneratingFlashcards = true
            defer { isGeneratingFlashcards = false }
            currentError = nil

            do {
                let cards = try await ai.generateFlashcards(from: entry.extractedText, count: count)
                guard !Task.isCancelled else { return }
                entry.storedFlashcards = cards.map {
                    FlashcardData(front: $0.front, back: $0.back)
                }
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
        case .summarize:
            generateSummary()
        case .generateFlashcards(let count):
            generateFlashcards(count: count)
        }
    }
}
