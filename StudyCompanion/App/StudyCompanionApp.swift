//
//  StudyCompanionApp.swift
//  StudyCompanion
//
//  Created by Adnan Boxwala on 28.02.26.
//

import SwiftUI
import SwiftData

@main
struct StudyCompanionApp: App {
    let container: ModelContainer

    init() {
        do {
            let config = ModelConfiguration(
                cloudKitDatabase: .private("iCloud.com.github.AdnanBoxwala.StudyCompanion")
            )
            container = try ModelContainer(
                for: Schema(SchemaV2.models),
                migrationPlan: StudyCompanionMigrationPlan.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
