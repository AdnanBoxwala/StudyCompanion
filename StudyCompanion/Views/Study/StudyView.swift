import SwiftUI
import PhotosUI

struct StudyView: View {
    @State private var viewModel = StudyViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var imageToView: UIImage?
    @State private var showSaveSheet = false
    @State private var flashcardCount = 5

    var body: some View {
        NavigationStack(path: $navigationPath) {
            mainContent
            .navigationTitle("Study")
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .extractedText:
                    ExtractedTextView(text: viewModel.extractedText)
                case .summary:
                    if let summary = viewModel.summary {
                        SummaryView(summary: summary)
                    }
                case .flashcards:
                    FlashcardListView(flashcards: viewModel.flashcards)
                }
            }
            .sheet(isPresented: $showSaveSheet) {
                SaveStudyView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Navigation Destinations

    enum Destination: Hashable {
        case extractedText
        case summary
        case flashcards
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                PhotoSectionView(
                    viewModel: viewModel,
                    imageToView: $imageToView
                )
                if !viewModel.selectedImages.isEmpty && viewModel.extractedText.isEmpty && !viewModel.isExtractingText {
                    Button {
                        viewModel.extractText()
                    } label: {
                        Label("Extract Text", systemImage: "doc.text.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
                if viewModel.isExtractingText {
                    ProgressView("Extracting text...")
                }
                if let error = viewModel.currentError {
                    ErrorBannerView(error: error) {
                        viewModel.retryLastAction()
                    }
                }
                if !viewModel.extractedText.isEmpty {
                    ResultLinkView(
                        title: "Extracted Text",
                        icon: "doc.text",
                        color: .gray
                    ) {
                        navigationPath.append(Destination.extractedText)
                    }
                    ActionButtonsView(
                        viewModel: viewModel,
                        flashcardCount: $flashcardCount
                    )
                }
                if viewModel.isSummarizing {
                    ProgressView("Summarizing...")
                }
                if viewModel.summary != nil {
                    ResultLinkView(
                        title: "Summary",
                        icon: "text.badge.star",
                        color: .blue
                    ) {
                        navigationPath.append(Destination.summary)
                    }
                }
                if viewModel.isGeneratingFlashcards {
                    ProgressView("Generating flashcards...")
                }
                if !viewModel.flashcards.isEmpty {
                    ResultLinkView(
                        title: "Flashcards (\(viewModel.flashcards.count))",
                        icon: "rectangle.on.rectangle",
                        color: .orange
                    ) {
                        navigationPath.append(Destination.flashcards)
                    }
                }
                if viewModel.canSave {
                    Button {
                        showSaveSheet = true
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.selectedImages.isEmpty {
                    Button("Reset", systemImage: "arrow.counterclockwise") {
                        viewModel.reset()
                    }
                }
            }
        }
    }

}
