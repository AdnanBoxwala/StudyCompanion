import SwiftUI

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

#Preview("Flashcard List") {
    NavigationStack {
        FlashcardListView(flashcards: [
            Flashcard(front: "What is Swift?", back: "A programming language by Apple"),
            Flashcard(front: "What is SwiftUI?", back: "A declarative UI framework"),
        ])
    }
}
