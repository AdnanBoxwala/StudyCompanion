import SwiftUI

struct ActionButtonsView: View {
    let viewModel: StudyViewModel
    @Binding var flashcardCount: Int

    var body: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.summarizeText()
            } label: {
                Label("Summarize", systemImage: "text.badge.star")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSummarizing || viewModel.extractedText.isEmpty)

            Stepper("Flashcards: \(flashcardCount)", value: $flashcardCount, in: 3...15)

            Button {
                viewModel.generateFlashcards(count: flashcardCount)
            } label: {
                Label("Generate Flashcards", systemImage: "rectangle.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(viewModel.isGeneratingFlashcards || viewModel.extractedText.isEmpty)
        }
    }
}
