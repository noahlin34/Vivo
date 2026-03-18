//
//  VivoApp.swift
//  Vivo
//
//  Created by Noah Lin  on 2026-02-19.
//

import SwiftUI
import SwiftData

@main
struct VivoApp: App {
    let sharedModelContainer: ModelContainer
    @State private var containerError: String? = nil

    init() {
        let schema = Schema([
            Medication.self,
            Doctor.self,
            Appointment.self,
            HealthNote.self,
            VitalRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Provide a non-nil placeholder so the stored property is always initialized.
            // The error state is surfaced via the containerError string.
            sharedModelContainer = try! ModelContainer(for: Schema([]), configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
            containerError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let errorMessage = containerError {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("Unable to load data")
                        .font(.system(size: 22, weight: .semibold))
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else {
                LaunchGateView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
