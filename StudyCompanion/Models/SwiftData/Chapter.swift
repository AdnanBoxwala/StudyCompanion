import Foundation
import SwiftData

@Model
final class Chapter {
    var name: String = ""
    var subject: Subject?
    @Relationship(deleteRule: .cascade, inverse: \StudyEntry.chapter)
    var entries: [StudyEntry]?
    var createdAt: Date = Date()

    init(name: String, subject: Subject) {
        self.name = name
        self.subject = subject
    }
}
