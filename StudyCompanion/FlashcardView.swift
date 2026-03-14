import SwiftUI

// MARK: - Flashcard List View

struct FlashcardListView: View {
    let flashcards: [Flashcard]

    /// Convenience init for stored data from SwiftData.
    init(storedFlashcards: [FlashcardData]) {
        self.flashcards = storedFlashcards.map {
            Flashcard(front: $0.front, back: $0.back)
        }
    }

    /// Init for in-memory flashcards from AI generation.
    init(flashcards: [Flashcard]) {
        self.flashcards = flashcards
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NavigationLink {
                    FlashcardReviewView(flashcards: flashcards)
                } label: {
                    Label("Start Review", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .padding(.horizontal)

                ForEach(flashcards) { card in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Q: \(card.front)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("A: \(card.back)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Flashcards (\(flashcards.count))")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Flashcard Review View (flip cards)

struct FlashcardReviewView: View {
    let flashcards: [Flashcard]
    @State private var currentIndex = 0
    @State private var isFlipped = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Card \(currentIndex + 1) of \(flashcards.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            cardView
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isFlipped.toggle()
                    }
                }

            Text("Tap card to flip")
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack(spacing: 40) {
                Button {
                    goToPrevious()
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.largeTitle)
                }
                .disabled(currentIndex == 0)

                Button {
                    goToNext()
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.largeTitle)
                }
                .disabled(currentIndex == flashcards.count - 1)
            }
        }
        .padding()
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var cardView: some View {
        let card = flashcards[currentIndex]

        return ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(isFlipped ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                .shadow(radius: 4)

            VStack(spacing: 12) {
                Text(isFlipped ? "Answer" : "Question")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(isFlipped ? card.back : card.front)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
        }
        .frame(height: 250)
        .padding(.horizontal)
    }

    private func goToPrevious() {
        guard currentIndex > 0 else { return }
        isFlipped = false
        withAnimation {
            currentIndex -= 1
        }
    }

    private func goToNext() {
        guard currentIndex < flashcards.count - 1 else { return }
        isFlipped = false
        withAnimation {
            currentIndex += 1
        }
    }
}

#Preview("Flashcard List") {
    NavigationStack {
        FlashcardListView(flashcards: [
            Flashcard(front: "What is Swift?", back: "A programming language by Apple"),
            Flashcard(front: "What is SwiftUI?", back: "A declarative UI framework"),
        ])
    }
}
#Preview("Flashcard Review") {
    NavigationStack {
        FlashcardReviewView(flashcards: [
            Flashcard(front: "What is Swift?", back: "A programming language by Apple"),
            Flashcard(front: "What is SwiftUI?", back: "A declarative UI framework"),
        ])
    }
}

