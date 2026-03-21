import SwiftUI
import Testing
@testable import StudyCompanion

// MARK: - Test Helpers

/// Creates a UIImage with the given text rendered on it.
private func makeImageWithText(_ text: String, size: CGSize = CGSize(width: 400, height: 200)) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        // White background
        UIColor.white.setFill()
        context.fill(CGRect(origin: .zero, size: size))

        // Draw black text
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32),
            .foregroundColor: UIColor.black
        ]
        let nsText = text as NSString
        nsText.draw(
            in: CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40),
            withAttributes: attributes
        )
    }
}

/// Creates a blank white UIImage with no text.
private func makeBlankImage(size: CGSize = CGSize(width: 200, height: 200)) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        UIColor.white.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
}

// MARK: - AppleOCRService Tests

@Suite("AppleOCRService")
struct AppleOCRServiceTests {

    let service = AppleOCRService()

    @Test("Throws noImages when given an empty array")
    func emptyImagesThrows() async {
        do {
            _ = try await service.extractText(from: [])
            Issue.record("Expected OCRError.noImages")
        } catch {
            if case OCRError.noImages = error {
                // Expected
            } else {
                Issue.record("Expected OCRError.noImages, got \(error)")
            }
        }
    }

    @Test("Extracts text from an image with rendered text")
    func extractsTextFromRenderedImage() async throws {
        let image = makeImageWithText("Hello World")
        let result = try await service.extractText(from: [image])

        #expect(result.lowercased().contains("hello"))
    }

    @Test("Extracts text from multiple images and separates with double newline")
    func multipleImagesJoined() async throws {
        let image1 = makeImageWithText("First Page")
        let image2 = makeImageWithText("Second Page")
        let result = try await service.extractText(from: [image1, image2])

        #expect(result.contains("First"))
        #expect(result.contains("Second"))
        // Pages should be separated by double newline
        #expect(result.contains("\n\n"))
    }

    @Test("Throws noTextFound when images contain no recognizable text")
    func blankImageThrows() async {
        let blank = makeBlankImage()
        do {
            _ = try await service.extractText(from: [blank])
            Issue.record("Expected OCRError.noTextFound")
        } catch {
            if case OCRError.noTextFound = error {
                // Expected
            } else {
                Issue.record("Expected OCRError.noTextFound, got \(error)")
            }
        }
    }

    @Test("Skips images without a cgImage and still processes valid ones")
    func skipsInvalidCGImage() async throws {
        // A valid image with text
        let goodImage = makeImageWithText("Valid Text")

        // CIImage-backed UIImage has no cgImage
        let ciOnly = UIImage(ciImage: CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100)))

        let result = try await service.extractText(from: [ciOnly, goodImage])

        #expect(result.contains("Valid"))
    }
}

// MARK: - OCRError Tests

@Suite("OCRError")
struct OCRErrorTests {

    @Test("OCRError cases are distinct")
    func errorCases() {
        let noImages = OCRError.noImages
        let noText = OCRError.noTextFound
        let failed = OCRError.recognitionFailed(underlying: NSError(domain: "test", code: 1))

        if case .noImages = noImages {} else { Issue.record("Expected .noImages") }
        if case .noTextFound = noText {} else { Issue.record("Expected .noTextFound") }
        if case .recognitionFailed = failed {} else { Issue.record("Expected .recognitionFailed") }
    }

    @Test("recognitionFailed wraps underlying error")
    func recognitionFailedWrapsError() {
        let underlying = NSError(domain: "VisionTest", code: 42, userInfo: [NSLocalizedDescriptionKey: "Vision failed"])
        let error = OCRError.recognitionFailed(underlying: underlying)

        if case .recognitionFailed(let wrapped) = error {
            let nsError = wrapped as NSError
            #expect(nsError.domain == "VisionTest")
            #expect(nsError.code == 42)
        } else {
            Issue.record("Expected .recognitionFailed")
        }
    }
}

// MARK: - PhotoLoadingError Tests

@Suite("PhotoLoadingError")
struct PhotoLoadingErrorTests {

    @Test("PhotoLoadingError cases are distinct")
    func errorCases() {
        let noData = PhotoLoadingError.noData
        let decoding = PhotoLoadingError.decodingFailed
        let transfer = PhotoLoadingError.transferFailed(underlying: NSError(domain: "test", code: 1))

        if case .noData = noData {} else { Issue.record("Expected .noData") }
        if case .decodingFailed = decoding {} else { Issue.record("Expected .decodingFailed") }
        if case .transferFailed = transfer {} else { Issue.record("Expected .transferFailed") }
    }

    @Test("transferFailed wraps underlying error")
    func transferFailedWrapsError() {
        let underlying = NSError(domain: "PhotosTest", code: 99, userInfo: [NSLocalizedDescriptionKey: "Transfer failed"])
        let error = PhotoLoadingError.transferFailed(underlying: underlying)

        if case .transferFailed(let wrapped) = error {
            let nsError = wrapped as NSError
            #expect(nsError.domain == "PhotosTest")
            #expect(nsError.code == 99)
        } else {
            Issue.record("Expected .transferFailed")
        }
    }
}

// MARK: - PhotoLoadingService Protocol Tests (via Mock)

/// ApplePhotoLoadingService can't be unit tested directly because PhotosPickerItem
/// has no public initializer. These tests verify the protocol contract using the mock
/// from StudyViewModelTests, ensuring the error paths work correctly.

@Suite("PhotoLoadingService Protocol")
struct PhotoLoadingServiceProtocolTests {

    @Test("Mock returns images on success")
    func mockSuccess() async throws {
        let mock = MockPhotoLoadingService(result: .success([UIImage(), UIImage()]))
        let images = try await mock.loadImages(from: [])

        #expect(images.count == 2)
    }

    @Test("Mock throws noData error")
    func mockNoData() async {
        let mock = MockPhotoLoadingService(result: .failure(.noData))
        do {
            _ = try await mock.loadImages(from: [])
            Issue.record("Expected PhotoLoadingError.noData")
        } catch {
            if case PhotoLoadingError.noData = error {
                // Expected
            } else {
                Issue.record("Expected .noData, got \(error)")
            }
        }
    }

    @Test("Mock throws decodingFailed error")
    func mockDecodingFailed() async {
        let mock = MockPhotoLoadingService(result: .failure(.decodingFailed))
        do {
            _ = try await mock.loadImages(from: [])
            Issue.record("Expected PhotoLoadingError.decodingFailed")
        } catch {
            if case PhotoLoadingError.decodingFailed = error {
                // Expected
            } else {
                Issue.record("Expected .decodingFailed, got \(error)")
            }
        }
    }

    @Test("Mock throws transferFailed error")
    func mockTransferFailed() async {
        let underlying = NSError(domain: "test", code: 1)
        let mock = MockPhotoLoadingService(result: .failure(.transferFailed(underlying: underlying)))
        do {
            _ = try await mock.loadImages(from: [])
            Issue.record("Expected PhotoLoadingError.transferFailed")
        } catch {
            if case PhotoLoadingError.transferFailed = error {
                // Expected
            } else {
                Issue.record("Expected .transferFailed, got \(error)")
            }
        }
    }
}
