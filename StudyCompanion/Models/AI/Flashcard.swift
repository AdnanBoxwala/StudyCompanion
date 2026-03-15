import Foundation

struct Flashcard: Identifiable, Codable {
    let id: UUID
    var front: String
    var back: String

    init(id: UUID = UUID(), front: String, back: String) {
        self.id = id
        self.front = front
        self.back = back
    }
}
