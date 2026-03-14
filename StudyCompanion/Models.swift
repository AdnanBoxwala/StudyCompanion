import Foundation
import SwiftData
import FoundationModels

// MARK: - In-Memory Models

struct Flashcard: Identifiable, Codable {
    let id: UUID
    var front: String
    var back: String

    init(id: UUID = UUID(), front: String, back: String) {
        self.id = id
        self.front = front
        self.back = back
    }
}

// MARK: - SwiftData Persistence Models

@Model
final class Subject {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \Chapter.subject)
    var chapters: [Chapter] = []
    var createdAt: Date = Date()

    init(name: String) {
        self.name = name
    }
}

@Model
final class Chapter {
    var name: String
    var subject: Subject?
    @Relationship(deleteRule: .cascade, inverse: \StudyEntry.chapter)
    var entries: [StudyEntry] = []
    var createdAt: Date = Date()

    init(name: String, subject: Subject) {
        self.name = name
        self.subject = subject
    }
}

@Model
final class StudyEntry {
    var topicName: String
    var extractedText: String
    var summaryText: String?
    var keyPoints: [String]?
    var storedFlashcards: [FlashcardData]?
    var chapter: Chapter?
    var createdAt: Date = Date()

    init(topicName: String, extractedText: String, summaryText: String? = nil, keyPoints: [String]? = nil, storedFlashcards: [FlashcardData]? = nil, chapter: Chapter) {
        self.topicName = topicName
        self.extractedText = extractedText
        self.summaryText = summaryText
        self.keyPoints = keyPoints
        self.storedFlashcards = storedFlashcards
        self.chapter = chapter
    }

    var hasFlashcards: Bool {
        guard let cards = storedFlashcards else { return false }
        return !cards.isEmpty
    }

    var hasSummary: Bool {
        summaryText != nil
    }
}

struct FlashcardData: Codable {
    var front: String
    var back: String
}

// MARK: - Generable Types for Apple Intelligence

@Generable(description: "A concise summary of the provided text")
struct TextSummary {
    @Guide(description: "A clear, concise summary of the key points in 2-4 sentences")
    var summary: String

    @Guide(description: "A list of 3-5 key points extracted from the text")
    var keyPoints: [String]
}

@Generable(description: "A flashcard with a question on the front and answer on the back")
struct GeneratedFlashcard {
    @Guide(description: "A clear question or term for the front of the flashcard")
    var front: String

    @Guide(description: "A concise answer or definition for the back of the flashcard")
    var back: String
}

@Generable(description: "A set of flashcards generated from study material")
struct FlashcardSet {
    @Guide(description: "A list of flashcards covering the key concepts from the text", .maximumCount(15))
    var cards: [GeneratedFlashcard]
}
