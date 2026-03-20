import Foundation
import SwiftData

@Model
final class StudyEntry {
    var topicName: String = ""
    var extractedText: String = ""
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
