import SwiftUI

struct ResultLinkView: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            action()
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
}

#Preview {
    VStack(spacing: 12) {
        ResultLinkView(title: "Extracted Text", icon: "doc.text", color: .gray) {}
        ResultLinkView(title: "Summary", icon: "text.badge.star", color: .blue) {}
        ResultLinkView(title: "Flashcards (5)", icon: "rectangle.on.rectangle", color: .orange) {}
    }
    .padding()
}
