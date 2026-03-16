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
import UserNotifications

@main
struct VivoApp: App {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Medication.self,
            Doctor.self,
            Appointment.self,
            HealthNote.self,
            VitalRecord.self,
        ])
        // CloudKit sync only works on a physical device with the iCloud container
        // configured in the Apple Developer Portal. Disable it on the simulator
        // to avoid launch lag, AttributeGraph cycles, and CloudKit export errors.
        #if targetEnvironment(simulator)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        #else
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.noahlin.Vivo")
        )
        #endif
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .onAppear {
                        UNUserNotificationCenter.current()
                            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
                    }
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
