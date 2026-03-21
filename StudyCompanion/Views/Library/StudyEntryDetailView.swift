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

            // MARK: - Error
            if let error = viewModel?.currentError {
                ErrorBannerView(error: error, onRetry: {})
            }
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
