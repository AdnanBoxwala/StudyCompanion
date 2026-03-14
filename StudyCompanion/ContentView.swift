import SwiftUI
import PhotosUI
import FoundationModels

// MARK: - Root TabView

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Study", systemImage: "text.viewfinder") {
                StudyView()
            }
            Tab("Library", systemImage: "books.vertical") {
                LibraryView()
            }
        }
    }
}

// MARK: - Study View

struct StudyView: View {
    @State private var viewModel = StudyViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var imageToView: UIImage?
    @State private var showSaveSheet = false
    @State private var flashcardCount = 5

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                switch viewModel.modelAvailability {
                case .available:
                    mainContent
                case .unavailable(.deviceNotEligible):
                    unavailableView(
                        title: "Device Not Supported",
                        message: "This app requires Apple Intelligence, which is available on iPhone 15 Pro and later."
                    )
                case .unavailable(.appleIntelligenceNotEnabled):
                    unavailableView(
                        title: "Apple Intelligence Disabled",
                        message: "Please enable Apple Intelligence in Settings to use this app."
                    )
                case .unavailable(.modelNotReady):
                    unavailableView(
                        title: "Model Loading",
                        message: "Apple Intelligence is preparing. Please try again shortly."
                    )
                case .unavailable:
                    unavailableView(
                        title: "Unavailable",
                        message: "Apple Intelligence is currently unavailable."
                    )
                }
            }
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

    private enum Destination: Hashable {
        case extractedText
        case summary
        case flashcards
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                photoSection
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
                    errorBanner(error)
                }
                if !viewModel.extractedText.isEmpty {
                    resultLink(
                        title: "Extracted Text",
                        icon: "doc.text",
                        color: .gray,
                        destination: .extractedText
                    )
                    actionButtons
                }
                if viewModel.isSummarizing {
                    ProgressView("Summarizing...")
                }
                if viewModel.summary != nil {
                    resultLink(
                        title: "Summary",
                        icon: "text.badge.star",
                        color: .blue,
                        destination: .summary
                    )
                }
                if viewModel.isGeneratingFlashcards {
                    ProgressView("Generating flashcards...")
                }
                if !viewModel.flashcards.isEmpty {
                    resultLink(
                        title: "Flashcards (\(viewModel.flashcards.count))",
                        icon: "rectangle.on.rectangle",
                        color: .orange,
                        destination: .flashcards
                    )
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

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(spacing: 12) {
            if !viewModel.selectedImages.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { _, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .onTapGesture {
                                    imageToView = image
                                }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .scrollIndicators(.hidden)
                .fullScreenCover(item: $imageToView) { image in
                    ImageViewer(image: image)
                }
            } else {
                PhotosPicker(
                    selection: $viewModel.selectedPhotoItems,
                    maxSelectionCount: 3,
                    matching: .images
                ) {
                    Label("Select Photos (up to 3)", systemImage: "photo.on.rectangle.angled")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                .foregroundStyle(.secondary)
                        )
                }
            }
        }
        .onChange(of: viewModel.selectedPhotoItems) {
            viewModel.loadImages()
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
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

    // MARK: - Result Link

    private func resultLink(title: String, icon: String, color: Color, destination: Destination) -> some View {
        Button {
            navigationPath.append(destination)
        } label: {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Views

    private func unavailableView(title: String, message: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: "brain")
        } description: {
            Text(message)
        }
    }

    private func errorBanner(_ error: StudyError) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(error.errorDescription ?? "An error occurred.")
                    .font(.caption)
            }
            if error.isRetryable {
                Button {
                    viewModel.retryLastAction()
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(0.1))
        )
    }
}

// MARK: - UIImage + Identifiable

extension UIImage: @retroactive Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}

// MARK: - Image Viewer

private struct ImageViewer: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var zoom: CGFloat = 1.0
    @State private var lastZoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(zoom)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            zoom = max(1.0, lastZoom * value.magnification)
                        }
                        .onEnded { value in
                            zoom = max(1.0, lastZoom * value.magnification)
                            lastZoom = zoom
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        zoom = 1.0
                        lastZoom = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .gray.opacity(0.5))
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
