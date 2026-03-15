import SwiftUI
import Vision

protocol OCRService: Sendable {
    func extractText(from images: [UIImage]) async throws(OCRError) -> String
}

struct AppleOCRService: OCRService {
    func extractText(from images: [UIImage]) async throws(OCRError) -> String {
        guard !images.isEmpty else { throw .noImages }

        var allPageTexts: [String] = []

        for image in images {
            guard !Task.isCancelled else { break }
            guard let cgImage = image.cgImage else { continue }

            do {
                var request = RecognizeTextRequest()
                request.recognitionLevel = .accurate
                let observations = try await request.perform(on: cgImage)
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                let pageText = recognizedStrings.joined(separator: "\n")
                if !pageText.isEmpty {
                    allPageTexts.append(pageText)
                }
            } catch {
                throw .recognitionFailed(underlying: error)
            }
        }

        let result = allPageTexts.joined(separator: "\n\n")
        guard !result.isEmpty else { throw .noTextFound }
        return result
    }
}
