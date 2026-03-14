import SwiftUI
import SwiftData

// MARK: - Library View (Subjects list)

struct LibraryView: View {
    @Query(sort: \Subject.name) private var subjects: [Subject]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if subjects.isEmpty {
                    ContentUnavailableView(
                        "No Saved Studies",
                        systemImage: "books.vertical",
                        description: Text("Study entries you save will appear here, organised by subject and chapter.")
                    )
                } else {
                    List {
                        ForEach(subjects) { subject in
                            NavigationLink {
                                SubjectDetailView(subject: subject)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(subject.name)
                                        .font(.headline)
                                    Text("\(subject.chapters.count) chapter(s)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteSubjects)
                    }
                }
            }
            .navigationTitle("Library")
        }
    }

    private func deleteSubjects(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(subjects[index])
        }
    }
}

// MARK: - Subject Detail View (Chapters list)

struct SubjectDetailView: View {
    let subject: Subject
    @Environment(\.modelContext) private var modelContext

    private var sortedChapters: [Chapter] {
        subject.chapters.sorted(by: { $0.name < $1.name })
    }

    var body: some View {
        List {
            ForEach(sortedChapters) { chapter in
                NavigationLink {
                    ChapterDetailView(chapter: chapter)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chapter.name)
                            .font(.headline)
                        Text("\(chapter.entries.count) entry/entries")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteChapters)
        }
        .navigationTitle(subject.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteChapters(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedChapters[index])
        }
    }
}

// MARK: - Chapter Detail View (Entries list)

struct ChapterDetailView: View {
    let chapter: Chapter
    @Environment(\.modelContext) private var modelContext

    private var sortedEntries: [StudyEntry] {
        chapter.entries.sorted(by: { $0.createdAt > $1.createdAt })
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

// MARK: - Study Entry Detail View

struct StudyEntryDetailView: View {
    let entry: StudyEntry

    var body: some View {
        List {
            // Extracted text
            NavigationLink {
                ExtractedTextView(text: entry.extractedText)
            } label: {
                Label("Extracted Text", systemImage: "doc.text")
            }

            // Summary
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

            // Flashcards
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
