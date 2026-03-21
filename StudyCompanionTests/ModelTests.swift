import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import StudyCompanion

// MARK: - Flashcard Tests

@Suite("Flashcard")
struct FlashcardTests {

    @Test("Flashcard stores front and back text")
    func creation() {
        let card = Flashcard(front: "What is 2+2?", back: "4")

        #expect(card.front == "What is 2+2?")
        #expect(card.back == "4")
    }

    @Test("Flashcard generates unique IDs")
    func uniqueIDs() {
        let card1 = Flashcard(front: "Q1", back: "A1")
        let card2 = Flashcard(front: "Q2", back: "A2")

        #expect(card1.id != card2.id)
    }

    @Test("Flashcard accepts custom ID")
    func customID() {
        let id = UUID()
        let card = Flashcard(id: id, front: "Q", back: "A")

        #expect(card.id == id)
    }

    @Test("Flashcard encodes and decodes via JSON")
    func codableRoundtrip() throws {
        let original = Flashcard(front: "Capital of France?", back: "Paris")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Flashcard.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.front == original.front)
        #expect(decoded.back == original.back)
    }

    @Test("Flashcard decodes from JSON string")
    func decodesFromJSON() throws {
        let id = UUID()
        let json = """
        {"id":"\(id.uuidString)","front":"Q","back":"A"}
        """
        let decoded = try JSONDecoder().decode(Flashcard.self, from: Data(json.utf8))

        #expect(decoded.id == id)
        #expect(decoded.front == "Q")
        #expect(decoded.back == "A")
    }
}

// MARK: - FlashcardData Tests

@Suite("FlashcardData")
struct FlashcardDataTests {

    @Test("FlashcardData stores front and back")
    func creation() {
        let data = FlashcardData(front: "Term", back: "Definition")

        #expect(data.front == "Term")
        #expect(data.back == "Definition")
    }

    @Test("FlashcardData encodes and decodes via JSON")
    func codableRoundtrip() throws {
        let original = FlashcardData(front: "Mitosis", back: "Cell division")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FlashcardData.self, from: encoded)

        #expect(decoded.front == original.front)
        #expect(decoded.back == original.back)
    }

    @Test("Array of FlashcardData roundtrips correctly")
    func arrayRoundtrip() throws {
        let originals = [
            FlashcardData(front: "Q1", back: "A1"),
            FlashcardData(front: "Q2", back: "A2"),
            FlashcardData(front: "Q3", back: "A3")
        ]
        let encoded = try JSONEncoder().encode(originals)
        let decoded = try JSONDecoder().decode([FlashcardData].self, from: encoded)

        #expect(decoded.count == 3)
        #expect(decoded[0].front == "Q1")
        #expect(decoded[2].back == "A3")
    }
}

// MARK: - TextSummary Tests

@Suite("TextSummary")
struct TextSummaryTests {

    @Test("TextSummary stores summary and keyPoints")
    func creation() {
        let ts = TextSummary(summary: "Overview of photosynthesis", keyPoints: ["Light", "Water", "CO2"])

        #expect(ts.summary == "Overview of photosynthesis")
        #expect(ts.keyPoints.count == 3)
        #expect(ts.keyPoints.first == "Light")
    }

    @Test("TextSummary with empty keyPoints")
    func emptyKeyPoints() {
        let ts = TextSummary(summary: "Brief", keyPoints: [])

        #expect(ts.summary == "Brief")
        #expect(ts.keyPoints.isEmpty)
    }
}

// MARK: - StudyEntry Computed Properties Tests

@Suite("StudyEntry Computed Properties")
struct StudyEntryComputedPropertyTests {

    @MainActor
    private func makeContext() throws -> (ModelContainer, ModelContext, Chapter) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Subject.self, Chapter.self, StudyEntry.self,
            configurations: config
        )
        let context = container.mainContext
        let subject = Subject(name: "Science")
        context.insert(subject)
        let chapter = Chapter(name: "Biology", subject: subject)
        context.insert(chapter)
        return (container, context, chapter)
    }

    @Test("hasFlashcards is false when storedFlashcards is nil")
    @MainActor
    func hasFlashcardsNil() throws {
        let (container, context, chapter) = try makeContext()
        _ = container
        let entry = StudyEntry(topicName: "Test", extractedText: "Text", chapter: chapter)
        context.insert(entry)

        #expect(entry.hasFlashcards == false)
    }

    @Test("hasFlashcards is false when storedFlashcards is empty")
    @MainActor
    func hasFlashcardsEmpty() throws {
        let (container, context, chapter) = try makeContext()
        _ = container
        let entry = StudyEntry(topicName: "Test", extractedText: "Text", storedFlashcards: [], chapter: chapter)
        context.insert(entry)

        #expect(entry.hasFlashcards == false)
    }

    @Test("hasFlashcards is true when storedFlashcards has items")
    @MainActor
    func hasFlashcardsWithData() throws {
        let (container, context, chapter) = try makeContext()
        _ = container
        let cards = [FlashcardData(front: "Q", back: "A")]
        let entry = StudyEntry(topicName: "Test", extractedText: "Text", storedFlashcards: cards, chapter: chapter)
        context.insert(entry)

        #expect(entry.hasFlashcards == true)
    }

    @Test("hasSummary is false when summaryText is nil")
    @MainActor
    func hasSummaryNil() throws {
        let (container, context, chapter) = try makeContext()
        _ = container
        let entry = StudyEntry(topicName: "Test", extractedText: "Text", chapter: chapter)
        context.insert(entry)

        #expect(entry.hasSummary == false)
    }

    @Test("hasSummary is true when summaryText is set")
    @MainActor
    func hasSummaryWithText() throws {
        let (container, context, chapter) = try makeContext()
        _ = container
        let entry = StudyEntry(topicName: "Test", extractedText: "Text", summaryText: "A summary", chapter: chapter)
        context.insert(entry)

        #expect(entry.hasSummary == true)
    }
}

// MARK: - SyncState Tests

@Suite("SyncState")
struct SyncStateTests {

    @Test("isSyncing returns true only for .syncing")
    func isSyncingProperty() {
        #expect(SyncMonitor.SyncState.syncing.isSyncing == true)
        #expect(SyncMonitor.SyncState.notStarted.isSyncing == false)
        #expect(SyncMonitor.SyncState.synced.isSyncing == false)
        #expect(SyncMonitor.SyncState.error("fail").isSyncing == false)
        #expect(SyncMonitor.SyncState.notAvailable.isSyncing == false)
    }
}

// MARK: - SyncMonitor Tests

@Suite("SyncMonitor")
struct SyncMonitorTests {

    @Test("Initial state is notStarted")
    @MainActor
    func initialState() {
        let monitor = SyncMonitor()

        #expect(monitor.syncState.isSyncing == false)
        #expect(monitor.lastSyncDate == nil)
    }

    @Test("statusLabel returns correct strings for each state")
    @MainActor
    func statusLabels() {
        let monitor = SyncMonitor()

        // Default: notStarted
        #expect(monitor.statusLabel == "Waiting to sync")
    }

    @Test("statusIcon returns correct SF Symbol for each state")
    @MainActor
    func statusIcons() {
        let monitor = SyncMonitor()

        // Default: notStarted
        #expect(monitor.statusIcon == "icloud")
    }

    @Test("statusColor returns correct color for each state")
    @MainActor
    func statusColors() {
        let monitor = SyncMonitor()

        // Default: notStarted
        #expect(monitor.statusColor == .secondary)
    }
}
