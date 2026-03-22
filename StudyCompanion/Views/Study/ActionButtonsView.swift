import SwiftUI
import FoundationModels

struct ActionButtonsView: View {
    let viewModel: StudyViewModel
    @Binding var flashcardCount: Int

    private var isAIAvailable: Bool {
        viewModel.modelAvailability == .available
    }

    private var unavailableMessage: String? {
        switch viewModel.modelAvailability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "Apple Intelligence is not supported on this device."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Enable Apple Intelligence in Settings to use this feature."
        case .unavailable(.modelNotReady):
            return "Apple Intelligence is preparing. Please try again shortly."
        case .unavailable:
            return "Apple Intelligence is currently unavailable."
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            if let message = unavailableMessage {
                HStack(spacing: 8) {
                    Image(systemName: "brain")
                        .foregroundStyle(.orange)
                    Text(message)
                        .font(.caption)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.1))
                )
            }

            Button {
                viewModel.summarizeText()
            } label: {
                Label("Summarize", systemImage: "text.badge.star")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isAIAvailable || viewModel.isSummarizing || viewModel.extractedText.isEmpty)

            Stepper("Flashcards: \(flashcardCount)", value: $flashcardCount, in: 3...15)

            Button {
                viewModel.generateFlashcards(count: flashcardCount)
            } label: {
                Label("Generate Flashcards", systemImage: "rectangle.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(!isAIAvailable || viewModel.isGeneratingFlashcards || viewModel.extractedText.isEmpty)
        }
    }
}

#Preview {
    @Previewable @State var flashcardCount = 5

    ActionButtonsView(
        viewModel: StudyViewModel(),
        flashcardCount: $flashcardCount
    )
    .padding()
}
