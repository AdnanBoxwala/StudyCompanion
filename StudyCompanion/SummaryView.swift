import SwiftUI

struct SummaryView: View {
    let summaryText: String
    let keyPoints: [String]

    /// Convenience init for in-memory TextSummary from AI generation.
    init(summary: TextSummary) {
        self.summaryText = summary.summary
        self.keyPoints = summary.keyPoints
    }

    /// Init for stored data from SwiftData.
    init(summaryText: String, keyPoints: [String]) {
        self.summaryText = summaryText
        self.keyPoints = keyPoints
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(summaryText)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                    )

                if !keyPoints.isEmpty {
                    Text("Key Points")
                        .font(.headline)

                    ForEach(keyPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .padding(.top, 3)
                            Text(point)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SummaryView(
            summaryText: "Swift is a programming language developed by Apple for building apps across all Apple platforms.",
            keyPoints: [
                "Developed by Apple",
                "Used for iOS, macOS, watchOS, tvOS",
                "Modern and safe language"
            ]
        )
    }
}
