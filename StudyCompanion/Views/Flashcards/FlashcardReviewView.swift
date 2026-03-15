import SwiftUI

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

#Preview("Flashcard Review") {
    NavigationStack {
        FlashcardReviewView(flashcards: [
            Flashcard(front: "What is Swift?", back: "A programming language by Apple"),
            Flashcard(front: "What is SwiftUI?", back: "A declarative UI framework"),
        ])
    }
}
