import CoreData
import SwiftUI

/// Observes NSPersistentCloudKitContainer sync events and exposes current sync state.
@Observable
@MainActor
final class SyncMonitor {
    enum SyncState {
        case notStarted
        case syncing
        case synced
        case error(String)
        case notAvailable

        var isSyncing: Bool {
            if case .syncing = self { return true }
            return false
        }
    }

    private(set) var syncState: SyncState = .notStarted
    private(set) var lastSyncDate: Date?

    init(isCloudKitAvailable: Bool = true) {
        if !isCloudKitAvailable {
            syncState = .notAvailable
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(eventChanged(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil
        )
    }

    @objc nonisolated private func eventChanged(_ notification: Notification) {
        guard let event = notification.userInfo?[
            NSPersistentCloudKitContainer.eventNotificationUserInfoKey
        ] as? NSPersistentCloudKitContainer.Event else { return }

        Task { @MainActor in
            if event.endDate == nil {
                // Event is in progress
                syncState = .syncing
            } else if let error = event.error {
                syncState = .error(error.localizedDescription)
            } else {
                syncState = .synced
                lastSyncDate = event.endDate
            }
        }
    }

    var statusLabel: String {
        switch syncState {
        case .notStarted:
            return "Waiting to sync"
        case .syncing:
            return "Syncing..."
        case .synced:
            if let date = lastSyncDate {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .short
                return "Synced \(formatter.localizedString(for: date, relativeTo: .now))"
            }
            return "Synced"
        case .error(let message):
            return "Sync error: \(message)"
        case .notAvailable:
            return "iCloud not available"
        }
    }

    var statusIcon: String {
        switch syncState {
        case .notStarted: return "icloud"
        case .syncing: return "arrow.triangle.2.circlepath.icloud"
        case .synced: return "checkmark.icloud"
        case .error: return "exclamationmark.icloud"
        case .notAvailable: return "icloud.slash"
        }
    }

    var statusColor: Color {
        switch syncState {
        case .notStarted: return .secondary
        case .syncing: return .blue
        case .synced: return .green
        case .error: return .red
        case .notAvailable: return .secondary
        }
    }
}
