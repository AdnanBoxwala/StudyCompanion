import SwiftUI

struct ErrorBannerView: View {
    let error: StudyError
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(error.errorDescription ?? "An error occurred.")
                    .font(.caption)
            }
            if error.isRetryable {
                Button {
                    onRetry()
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

#Preview("Retryable Error") {
    ErrorBannerView(error: .ai(.rateLimited), onRetry: {})
        .padding()
}

#Preview("Non-Retryable Error") {
    ErrorBannerView(error: .ocr(.noTextFound), onRetry: {})
        .padding()
}
