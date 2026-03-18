//
//  LaunchGateView.swift
//  Vivo
//

import SwiftUI
import SwiftData

private enum LaunchState: Equatable {
    case checking
    case onboarding
    case welcomeBack
    case main
}

struct LaunchGateView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Environment(SyncMonitor.self) private var syncMonitor
    @Environment(\.modelContext) private var modelContext

    @State private var launchState: LaunchState = .checking
    @State private var timeoutTask: Task<Void, Never>? = nil

    var body: some View {
        Group {
            switch launchState {
            case .checking:
                Color.bg.ignoresSafeArea()
            case .onboarding:
                OnboardingView()
                    .transition(.opacity)
            case .welcomeBack:
                WelcomeBackView()
                    .transition(.opacity)
            case .main:
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: launchState)
        .onAppear {
            guard launchState == .checking else { return }

            if hasCompletedOnboarding {
                launchState = .main
                return
            }

            #if targetEnvironment(simulator)
            launchState = .onboarding
            return
            #endif

            // Fast path: data may already be local
            if hasExistingData() {
                launchState = .welcomeBack
                return
            }

            // Start 4-second timeout then fall through to onboarding
            timeoutTask = Task {
                try? await Task.sleep(for: .seconds(4))
                await MainActor.run {
                    if launchState == .checking {
                        launchState = .onboarding
                    }
                }
            }
        }
        .onChange(of: syncMonitor.hasCompletedFirstImport) { _, completed in
            guard completed, launchState == .checking else { return }
            timeoutTask?.cancel()
            launchState = hasExistingData() ? .welcomeBack : .onboarding
        }
        .onChange(of: syncMonitor.state) { _, newState in
            guard launchState == .checking else { return }
            switch newState {
            case .noAccount, .error, .unavailable:
                timeoutTask?.cancel()
                launchState = .onboarding
            default:
                break
            }
        }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            if completed {
                launchState = .main
            }
        }
    }

    private func hasExistingData() -> Bool {
        let counts = [
            (try? modelContext.fetchCount(FetchDescriptor<Medication>())) ?? 0,
            (try? modelContext.fetchCount(FetchDescriptor<Doctor>())) ?? 0,
            (try? modelContext.fetchCount(FetchDescriptor<Appointment>())) ?? 0,
            (try? modelContext.fetchCount(FetchDescriptor<HealthNote>())) ?? 0,
            (try? modelContext.fetchCount(FetchDescriptor<VitalRecord>())) ?? 0,
        ]
        return counts.reduce(0, +) > 0
    }
}
