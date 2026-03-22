import SwiftData
import SwiftUI
import FoundationModels

struct StudyEntryDetailView: View {
    let entry: StudyEntry
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: LibraryEntryViewModel?
    @State private var flashcardCount = 5

    private var isAIAvailable: Bool {
        viewModel?.isAIAvailable ?? false
    }

    var body: some View {
        List {
            // MARK: - Extracted Text (always present)
            NavigationLink {
                ExtractedTextView(text: entry.extractedText)
            } label: {
                Label("Extracted Text", systemImage: "doc.text")
            }

            // MARK: - Summary
            summarySection

            // MARK: - Flashcards
            flashcardsSection


        }
        .navigationTitle(entry.topicName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = LibraryEntryViewModel(
                    entry: entry,
                    modelContext: modelContext
                )
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel?.presentableError != nil },
                set: { if !$0 { viewModel?.currentError = nil } }
            ),
            presenting: viewModel?.presentableError
        ) { error in
            if error.isRetryable {
                Button("Retry") { viewModel?.retryLastAction() }
                Button("Cancel", role: .cancel) { }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: { error in
            Text(error.errorDescription ?? "An error occurred.")
        }
    }

    // MARK: - Summary Section

    @ViewBuilder
    private var summarySection: some View {
        if let summaryText = entry.summaryText {
            NavigationLink {
                SummaryView(
                    summaryText: summaryText,
                    keyPoints: entry.keyPoints ?? []
                )
            } label: {
                Label("Summary", systemImage: "text.badge.star")
            }
        } else {
            Section {
                if isAIAvailable {
                    Button {
                        viewModel?.generateSummary()
                    } label: {
                        HStack {
                            Label("Generate Summary", systemImage: "text.badge.star")
                            Spacer()
                            if viewModel?.isSummarizing == true {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel?.isSummarizing == true)
                } else {
                    aiUnavailableRow(label: "Summary")
                }
            } header: {
                Text("Summary")
            } footer: {
                Text("Not yet generated")
            }
        }
    }

    // MARK: - Flashcards Section

    @ViewBuilder
    private var flashcardsSection: some View {
        if let flashcards = entry.storedFlashcards, !flashcards.isEmpty {
            NavigationLink {
                FlashcardListView(storedFlashcards: flashcards)
            } label: {
                Label("Flashcards (\(flashcards.count))", systemImage: "rectangle.on.rectangle")
            }
        } else {
            Section {
                if isAIAvailable {
                    Stepper("Count: \(flashcardCount)", value: $flashcardCount, in: 3...15)

                    Button {
                        viewModel?.generateFlashcards(count: flashcardCount)
                    } label: {
                        HStack {
                            Label("Generate Flashcards", systemImage: "rectangle.on.rectangle")
                            Spacer()
                            if viewModel?.isGeneratingFlashcards == true {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel?.isGeneratingFlashcards == true)
                } else {
                    aiUnavailableRow(label: "Flashcards")
                }
            } header: {
                Text("Flashcards")
            } footer: {
                Text("Not yet generated")
            }
        }
    }

    // MARK: - AI Unavailable Row

    private func aiUnavailableRow(label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "brain")
                .foregroundStyle(.orange)
            Text("\(label) — requires Apple Intelligence")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("With Summary & Flashcards") {
    @Previewable @State var entry = StudyEntry(
        topicName: "Newton's Laws",
        extractedText: "An object in motion stays in motion...",
        summaryText: "Newton's three laws describe the relationship between forces and motion.",
        keyPoints: ["Inertia", "F=ma", "Action-Reaction"],
        storedFlashcards: [
            FlashcardData(front: "What is Newton's 1st law?", back: "Law of inertia"),
            FlashcardData(front: "What is F=ma?", back: "Newton's 2nd law")
        ],
        chapter: Chapter(name: "Mechanics", subject: Subject(name: "Physics"))
    )

    NavigationStack {
        StudyEntryDetailView(entry: entry)
    }
    .modelContainer(for: Subject.self, inMemory: true)
}

#Preview("Text Only") {
    @Previewable @State var entry = StudyEntry(
        topicName: "The Roman Republic",
        extractedText: "The Roman Republic was the era of classical Roman civilization...",
        chapter: Chapter(name: "Ancient Rome", subject: Subject(name: "History"))
    )

    NavigationStack {
        StudyEntryDetailView(entry: entry)
    }
    .modelContainer(for: Subject.self, inMemory: true)
}
