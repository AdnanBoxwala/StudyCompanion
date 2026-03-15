import SwiftUI
import SwiftData

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
