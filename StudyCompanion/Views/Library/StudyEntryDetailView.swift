import SwiftUI

struct StudyEntryDetailView: View {
    let entry: StudyEntry

    var body: some View {
        List {
            NavigationLink {
                ExtractedTextView(text: entry.extractedText)
            } label: {
                Label("Extracted Text", systemImage: "doc.text")
            }

            if let summaryText = entry.summaryText {
                NavigationLink {
                    SummaryView(
                        summaryText: summaryText,
                        keyPoints: entry.keyPoints ?? []
                    )
                } label: {
                    Label("Summary", systemImage: "text.badge.star")
                }
            }

            if let flashcards = entry.storedFlashcards, !flashcards.isEmpty {
                NavigationLink {
                    FlashcardListView(storedFlashcards: flashcards)
                } label: {
                    Label("Flashcards (\(flashcards.count))", systemImage: "rectangle.on.rectangle")
                }
            }
        }
        .navigationTitle(entry.topicName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
