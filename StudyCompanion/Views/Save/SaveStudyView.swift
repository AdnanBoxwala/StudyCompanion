import SwiftUI
import SwiftData

struct SaveStudyView: View {
    let viewModel: StudyViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.name) private var existingSubjects: [Subject]

    @State private var subjectName = ""
    @State private var chapterName = ""
    @State private var topicName = ""
    @State private var selectedSubject: Subject?
    @State private var useExistingSubject = false
    @State private var useExistingChapter = false
    @State private var selectedChapter: Chapter?

    private var canSave: Bool {
        let subject = useExistingSubject ? selectedSubject?.name : subjectName
        let chapter = useExistingChapter ? selectedChapter?.name : chapterName
        guard let subject, let chapter else { return false }
        return !subject.isEmpty && !chapter.isEmpty && !topicName.isEmpty
    }

    private var chaptersForSelectedSubject: [Chapter] {
        selectedSubject?.chapters.sorted(by: { $0.name < $1.name }) ?? []
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Subject") {
                    if !existingSubjects.isEmpty {
                        Toggle("Use existing subject", isOn: $useExistingSubject)
                    }
                    if useExistingSubject {
                        Picker("Subject", selection: $selectedSubject) {
                            Text("Select a subject").tag(nil as Subject?)
                            ForEach(existingSubjects) { subject in
                                Text(subject.name).tag(subject as Subject?)
                            }
                        }
                    } else {
                        TextField("New subject name", text: $subjectName)
                            .autocorrectionDisabled()
                    }
                }

                Section("Chapter") {
                    if useExistingSubject && !chaptersForSelectedSubject.isEmpty {
                        Toggle("Use existing chapter", isOn: $useExistingChapter)
                    }
                    if useExistingChapter && useExistingSubject {
                        Picker("Chapter", selection: $selectedChapter) {
                            Text("Select a chapter").tag(nil as Chapter?)
                            ForEach(chaptersForSelectedSubject) { chapter in
                                Text(chapter.name).tag(chapter as Chapter?)
                            }
                        }
                    } else {
                        TextField("New chapter name", text: $chapterName)
                            .autocorrectionDisabled()
                    }
                }

                Section("Topic") {
                    TextField("Topic name", text: $topicName)
                        .autocorrectionDisabled()
                }

                Section("Content to Save") {
                    Label("Extracted Text", systemImage: "doc.text")
                    if viewModel.summary != nil {
                        Label("Summary", systemImage: "text.badge.star")
                    }
                    if !viewModel.flashcards.isEmpty {
                        Label("Flashcards (\(viewModel.flashcards.count))", systemImage: "rectangle.on.rectangle")
                    }
                }
            }
            .navigationTitle("Save Study Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .onChange(of: selectedSubject) {
                selectedChapter = nil
                useExistingChapter = false
            }
        }
    }

    private func save() {
        let finalSubject = useExistingSubject ? (selectedSubject?.name ?? "") : subjectName
        let finalChapter = useExistingChapter ? (selectedChapter?.name ?? "") : chapterName

        viewModel.save(
            subjectName: finalSubject,
            chapterName: finalChapter,
            topicName: topicName,
            modelContext: modelContext
        )
        viewModel.reset()
        dismiss()
    }
}
