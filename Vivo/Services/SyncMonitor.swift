//
//  SyncMonitor.swift
//  Vivo
//

import Foundation
import CoreData
import CloudKit

enum SyncState {
    case idle
    case syncing
    case synced(Date)
    case error(String)
    case noAccount
    case unavailable
}

@Observable final class SyncMonitor {
    var state: SyncState = .idle
    var hasCompletedFirstImport: Bool = false

    var lastSyncDate: Date? {
        if case .synced(let date) = state { return date }
        return nil
    }

    var isSyncing: Bool {
        if case .syncing = state { return true }
        return false
    }

    #if !targetEnvironment(simulator)
    @ObservationIgnored private var eventObserver: NSObjectProtocol?
    #endif

    init() {
        #if targetEnvironment(simulator)
        state = .unavailable
        #else
        subscribeToCloudKitEvents()
        checkAccountStatus()
        #endif
    }

    #if !targetEnvironment(simulator)
    private func subscribeToCloudKitEvents() {
        eventObserver = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event else { return }
            // Ignore one-time setup events fired at launch
            guard event.type != .setup else { return }

            if event.endDate == nil {
                self.state = .syncing
            } else if let error = event.error {
                self.state = .error(error.localizedDescription)
            } else {
                self.state = .synced(event.endDate ?? Date())
                if event.type == .import {
                    self.hasCompletedFirstImport = true
                }
            }
        }
    }

    private func checkAccountStatus() {
        CKContainer.default().accountStatus { [weak self] status, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if status != .available {
                    self.state = .noAccount
                }
            }
        }
    }
    #endif
}
