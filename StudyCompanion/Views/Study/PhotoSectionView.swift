import SwiftUI
import PhotosUI
import VisionKit

struct PhotoSectionView: View {
    let viewModel: StudyViewModel
    @Binding var imageToView: UIImage?
    @State private var showScanner = false

    var body: some View {
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
                VStack(spacing: 12) {
                    PhotosPicker(
                        selection: Bindable(viewModel).selectedPhotoItems,
                        maxSelectionCount: 3,
                        matching: .images
                    ) {
                        Label("Select Photos", systemImage: "photo.on.rectangle.angled")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 90)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                    .foregroundStyle(.secondary)
                            )
                    }

                    if VNDocumentCameraViewController.isSupported {
                        Button {
                            showScanner = true
                        } label: {
                            Label("Scan Pages", systemImage: "doc.viewfinder")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 90)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                        .foregroundStyle(.secondary)
                                )
                        }
                    }
                }
                .fullScreenCover(isPresented: $showScanner) {
                    DocumentScannerView(
                        onScanComplete: { images in
                            showScanner = false
                            viewModel.addScannedImages(images)
                        },
                        onCancel: {
                            showScanner = false
                        }
                    )
                }
            }
        }
        .onChange(of: viewModel.selectedPhotoItems) {
            viewModel.loadImages()
        }
    }
}

extension UIImage: @retroactive Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}
