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
        ScrollView {
            VStack(spacing: 16) {
                extractedTextCard
                summaryCard
                flashcardsCard
            }
            .padding()
            .containerRelativeFrame(.horizontal)
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

    // MARK: - Extracted Text Card

    private var extractedTextCard: some View {
        NavigationLink {
            ExtractedTextView(text: entry.extractedText)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "doc.text")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 8))
                    Text("Extracted Text")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Text(entry.extractedText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        Group {
            if let summaryText = entry.summaryText {
                NavigationLink {
                    SummaryView(
                        summaryText: summaryText,
                        keyPoints: entry.keyPoints ?? []
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "text.badge.star")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(.purple, in: RoundedRectangle(cornerRadius: 8))
                            Text("Summary")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        Text(summaryText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.leading)

                        if let keyPoints = entry.keyPoints, !keyPoints.isEmpty {
                            keyPointsChips(keyPoints)
                        }
                    }
                    .cardStyle()
                }
                .buttonStyle(.plain)
                .transition(.blurReplace)
            } else {
                summaryGenerateCard
                    .transition(.blurReplace)
            }
        }
        .animation(.smooth(duration: 0.4), value: entry.summaryText != nil)
    }

    private var summaryGenerateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "text.badge.star")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.purple, in: RoundedRectangle(cornerRadius: 8))
                Text("Summary")
                    .font(.headline)
                Spacer()
            }

            if isAIAvailable {
                Button {
                    viewModel?.generateSummary()
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate Summary")
                            .fontWeight(.medium)
                        Spacer()
                        if viewModel?.isSummarizing == true {
                            ProgressView()
                                .transition(.opacity)
                        }
                    }
                    .padding(12)
                    .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(viewModel?.isSummarizing == true)
                .animation(.easeInOut, value: viewModel?.isSummarizing == true)

                Text("Not yet generated")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                aiUnavailableRow(label: "Summary")
            }
        }
        .cardStyle()
    }

    // MARK: - Flashcards Card

    private var flashcardsCard: some View {
        Group {
            if let flashcards = entry.storedFlashcards, !flashcards.isEmpty {
                NavigationLink {
                    FlashcardListView(storedFlashcards: flashcards)
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.on.rectangle")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(.orange, in: RoundedRectangle(cornerRadius: 8))
                            Text("Flashcards")
                                .font(.headline)
                            Spacer()
                            Text("\(flashcards.count)")
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.orange.opacity(0.12), in: Capsule())
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        // Mini preview of first card
                        if let first = flashcards.first {
                            HStack(spacing: 0) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Q")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.orange)
                                    Text(first.front)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .cardStyle()
                }
                .buttonStyle(.plain)
                .transition(.blurReplace)
            } else {
                flashcardsGenerateCard
                    .transition(.blurReplace)
            }
        }
        .animation(.smooth(duration: 0.4), value: entry.storedFlashcards?.isEmpty == false)
    }

    private var flashcardsGenerateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 8))
                Text("Flashcards")
                    .font(.headline)
                Spacer()
            }

            if isAIAvailable {
                Stepper("Count: \(flashcardCount)", value: $flashcardCount, in: 3...15)
                    .font(.subheadline)

                Button {
                    viewModel?.generateFlashcards(count: flashcardCount)
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate Flashcards")
                            .fontWeight(.medium)
                        Spacer()
                        if viewModel?.isGeneratingFlashcards == true {
                            ProgressView()
                                .transition(.opacity)
                        }
                    }
                    .padding(12)
                    .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(viewModel?.isGeneratingFlashcards == true)
                .animation(.easeInOut, value: viewModel?.isGeneratingFlashcards == true)

                Text("Not yet generated")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                aiUnavailableRow(label: "Flashcards")
            }
        }
        .cardStyle()
    }

    // MARK: - Key Points Chips

    private func keyPointsChips(_ keyPoints: [String]) -> some View {
        FlowLayout(spacing: 6) {
            ForEach(keyPoints.prefix(5), id: \.self) { point in
                Text(point)
                    .font(.caption)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(maxWidth: 200)
                    .background(.purple.opacity(0.12), in: Capsule())
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

// MARK: - Card Style Modifier

private struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private extension View {
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }
}

// MARK: - Flow Layout

/// A simple horizontal wrapping layout for tags/chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalWidth = max(totalWidth, x - spacing)
            totalHeight = y + rowHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

// MARK: - Previews

#Preview("With Summary & Flashcards") {
    @Previewable @State var entry = StudyEntry(
        topicName: "Newton's Laws",
        extractedText: "An object in motion stays in motion unless acted upon by an external force. Force equals mass times acceleration. For every action there is an equal and opposite reaction. These three laws form the foundation of classical mechanics.",
        summaryText: "Newton's three laws describe the relationship between forces and motion. They form the foundation of classical mechanics and explain how objects behave when forces act upon them.",
        keyPoints: ["An object at rest stays at rest unless acted upon", "Force equals mass times acceleration", "Every action has an equal and opposite reaction", "Foundation of classical mechanics", "Explains motion and force relationships"],
        storedFlashcards: [
            FlashcardData(front: "What is Newton's 1st law?", back: "Law of inertia — an object in motion stays in motion"),
            FlashcardData(front: "What is F=ma?", back: "Newton's 2nd law — force equals mass times acceleration"),
            FlashcardData(front: "What is Newton's 3rd law?", back: "For every action there is an equal and opposite reaction")
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
        extractedText: "The Roman Republic was the era of classical Roman civilization, led by the Roman people, beginning with the overthrow of the Roman Kingdom. Its government consisted of a complex set of checks and balances, with power divided between the Senate, the magistrates, and the popular assemblies.",
        chapter: Chapter(name: "Ancient Rome", subject: Subject(name: "History"))
    )

    NavigationStack {
        StudyEntryDetailView(entry: entry)
    }
    .modelContainer(for: Subject.self, inMemory: true)
}
