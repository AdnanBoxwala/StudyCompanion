import SwiftUI
import SwiftData

struct ChapterDetailView: View {
    let chapter: Chapter
    @Environment(\.modelContext) private var modelContext

    private var sortedEntries: [StudyEntry] {
        (chapter.entries ?? []).sorted(by: { $0.createdAt > $1.createdAt })
    }

    var body: some View {
        List {
            ForEach(sortedEntries) { entry in
                NavigationLink {
                    StudyEntryDetailView(entry: entry)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.topicName)
                            .font(.headline)

                        HStack(spacing: 12) {
                            if entry.hasSummary {
                                Label("Summary", systemImage: "text.badge.star")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                            if entry.hasFlashcards {
                                Label("Flashcards", systemImage: "rectangle.on.rectangle")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            if !entry.hasSummary && !entry.hasFlashcards {
                                Label("Text only", systemImage: "doc.text")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(entry.createdAt, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .onDelete(perform: deleteEntries)
        }
        .navigationTitle(chapter.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedEntries[index])
        }
    }
}
