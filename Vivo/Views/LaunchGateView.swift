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
    @State private var showCheckingUI: Bool = false

    var body: some View {
        Group {
            switch launchState {
            case .checking:
                if showCheckingUI {
                    checkingView
                        .transition(.opacity)
                } else {
                    Color.bg.ignoresSafeArea()
                }
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
        .animation(.easeInOut(duration: 0.4), value: showCheckingUI)
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

            // After 2s, reveal the checking screen with a spinner + escape hatch
            Task {
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run {
                    if launchState == .checking {
                        showCheckingUI = true
                    }
                }
            }
        }
        .onChange(of: syncMonitor.hasCompletedFirstImport) { _, completed in
            guard completed, launchState == .checking else { return }
            launchState = hasExistingData() ? .welcomeBack : .onboarding
        }
        .onChange(of: syncMonitor.state) { _, newState in
            guard launchState == .checking else { return }
            switch newState {
            case .noAccount, .error, .unavailable:
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

    private var checkingView: some View {
        ZStack {
            Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.cyanStart, Color.cyanEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 104, height: 104)
                            .warmShadowLg()
                        Image(systemName: "icloud.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                    }

                    Text("Looking for your data…")
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .foregroundStyle(Color.nearBlack)
                        .multilineTextAlignment(.center)

                    ProgressView()
                        .tint(Color.mutedFg)
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Button {
                    launchState = .onboarding
                } label: {
                    Text("Start fresh")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.mutedFg)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
            .padding(.bottom, 40)
            .background(Color.bg)
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
