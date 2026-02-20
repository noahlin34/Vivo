//
//  VivoApp.swift
//  Vivo
//
//  Created by Noah Lin  on 2026-02-19.
//
//  CloudKit sync requires:
//  1. The iCloud container "iCloud.com.noahlin.Vivo" must be created in the
//     Apple Developer Portal under Certificates, Identifiers & Profiles → Identifiers → iCloud Containers.
//  2. The app's App ID must have iCloud (CloudKit) capability enabled.
//  3. Testing on a physical device signed into iCloud.
//

import SwiftUI
import SwiftData

@main
struct VivoApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Medication.self,
            Doctor.self,
            Appointment.self,
            HealthNote.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.noahlin.Vivo")
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
