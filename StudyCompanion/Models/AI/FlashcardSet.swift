import FoundationModels

@Generable(description: "A flashcard with a question on the front and answer on the back")
struct GeneratedFlashcard {
    @Guide(description: "A clear question or term for the front of the flashcard")
    var front: String

    @Guide(description: "A concise answer or definition for the back of the flashcard")
    var back: String
}

@Generable(description: "A set of flashcards generated from study material")
struct FlashcardSet {
    @Guide(description: "A list of flashcards covering the key concepts from the text", .maximumCount(15))
    var cards: [GeneratedFlashcard]
}
