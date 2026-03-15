import SwiftUI

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

#Preview {
    ContentView()
}
