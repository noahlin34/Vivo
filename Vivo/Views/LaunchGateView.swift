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
    @State private var logoVisible: Bool = false
    @State private var statusVisible: Bool = false

    var body: some View {
        Group {
            switch launchState {
            case .checking:
                splashView
                    .transition(.opacity)
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

            // Spring the logo in after 0.3s (first frame stays as bare Color.bg)
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                await MainActor.run { logoVisible = true }
            }

            // After 2.5s show spinner + escape hatch if still checking
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                await MainActor.run {
                    if launchState == .checking { statusVisible = true }
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

    private var splashView: some View {
        ZStack {
            Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.tealStart, Color.tealEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                            .warmShadowLg()
                        Image(systemName: "heart.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.white)
                    }

                    Text("Vivo")
                        .font(.system(size: 42, weight: .regular, design: .serif))
                        .foregroundStyle(Color.nearBlack)

                    if statusVisible {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(Color.mutedFg)
                            Text("Looking for your data…")
                                .font(.system(size: 17))
                                .foregroundStyle(Color.mutedFg)
                        }
                        .transition(.opacity)
                    }
                }
                .scaleEffect(logoVisible ? 1 : 0.8)
                .opacity(logoVisible ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: logoVisible)
                .animation(.easeInOut(duration: 0.4), value: statusVisible)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if statusVisible {
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
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: statusVisible)
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
