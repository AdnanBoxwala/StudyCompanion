import FoundationModels

@Generable(description: "A concise summary of the provided text")
struct TextSummary {
    @Guide(description: "A clear, concise summary of the key points in 2-4 sentences")
    var summary: String

    @Guide(description: "A list of 3-5 key points extracted from the text")
    var keyPoints: [String]
}
