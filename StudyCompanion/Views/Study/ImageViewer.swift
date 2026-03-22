import SwiftUI

struct ImageViewer: View {
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
    ImageViewer(image: UIImage(systemName: "photo.artframe")!)
}
