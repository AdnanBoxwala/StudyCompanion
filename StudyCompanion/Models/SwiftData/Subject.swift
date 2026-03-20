import Foundation
import SwiftData

@Model
final class Subject {
    var name: String = ""
    @Relationship(deleteRule: .cascade, inverse: \Chapter.subject)
    var chapters: [Chapter] = []
    var createdAt: Date = Date()

    init(name: String) {
        self.name = name
    }
}
