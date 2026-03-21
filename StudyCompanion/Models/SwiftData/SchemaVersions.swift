import Foundation
import SwiftData

// MARK: - Current Schema

// Single schema version — no migration needed since the app hasn't shipped yet.
// When a new version ships, snapshot the current models into a VersionedSchema
// and add a MigrationStage before updating the live models.

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Subject.self, Chapter.self, StudyEntry.self]
    }
}

enum StudyCompanionMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
