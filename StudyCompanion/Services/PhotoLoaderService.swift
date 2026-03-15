import PhotosUI
import SwiftUI

protocol PhotoLoadingService: Sendable {
    func loadImages(from items: [PhotosPickerItem]) async throws(PhotoLoadingError) -> [UIImage]
}

struct ApplePhotoLoadingService: PhotoLoadingService {
    func loadImages(from items: [PhotosPickerItem]) async throws(PhotoLoadingError) -> [UIImage] {
        var images: [UIImage] = []
        for item in items {
            guard !Task.isCancelled else { return images }
            let data: Data?
            do {
                data = try await item.loadTransferable(type: Data.self)
            } catch {
                throw .transferFailed(underlying: error)
            }
            guard let data else { throw .noData }
            guard let image = UIImage(data: data) else { throw .decodingFailed }
            images.append(image)
        }
        return images
    }
}
