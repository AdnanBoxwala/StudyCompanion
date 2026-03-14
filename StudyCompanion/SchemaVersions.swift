import Foundation
import SwiftData

// MARK: - Schema V1 (Initial Release)

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Subject.self, Chapter.self, StudyEntry.self]
    }
}

// MARK: - Migration Plan

enum StudyCompanionMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // No migrations yet — V1 is the initial schema.
        // Future migrations go here, e.g.:
        // .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
        []
    }
}
