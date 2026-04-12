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
    @State private var syncMonitor: SyncMonitor

    init() {
        let schema = Schema(SchemaV1.models)
        let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

        if isTesting {
            // Use in-memory store for tests to avoid CloudKit issues
            do {
                let testConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                container = try ModelContainer(for: schema, configurations: testConfig)
                _syncMonitor = State(initialValue: SyncMonitor())
            } catch {
                fatalError("Failed to create test model container: \(error)")
            }
        } else {
            // Try CloudKit-backed storage first, fall back to local-only if it fails
            // (e.g. simulator without iCloud sign-in, or container not yet provisioned)
            do {
                let cloudConfig = ModelConfiguration(
                    cloudKitDatabase: .private("iCloud.com.github.AdnanBoxwala.StudyCompanion")
                )
                container = try ModelContainer(
                    for: schema,
                    migrationPlan: StudyCompanionMigrationPlan.self,
                    configurations: cloudConfig
                )
                _syncMonitor = State(initialValue: SyncMonitor())
            } catch {
                print("CloudKit container failed, falling back to local storage: \(error)")
                do {
                    let localConfig = ModelConfiguration(cloudKitDatabase: .none)
                    container = try ModelContainer(
                        for: schema,
                        migrationPlan: StudyCompanionMigrationPlan.self,
                        configurations: localConfig
                    )
                    _syncMonitor = State(initialValue: SyncMonitor(isCloudKitAvailable: false))
                } catch {
                    fatalError("Failed to create model container: \(error)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(syncMonitor)
        }
        .modelContainer(container)
    }
}
