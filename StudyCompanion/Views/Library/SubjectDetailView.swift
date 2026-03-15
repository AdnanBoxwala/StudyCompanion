import SwiftUI
import SwiftData

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
