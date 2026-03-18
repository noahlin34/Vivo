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
    @State private var showIcon = false
    @State private var showHeart = false
    @State private var showTitle = false
    @State private var heartbeatPhase = false
    @State private var statusVisible = false

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

            // Phase 1 — staggered logo entrance
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                await MainActor.run { showIcon = true }
                try? await Task.sleep(for: .seconds(0.25))
                await MainActor.run { showHeart = true }
                try? await Task.sleep(for: .seconds(0.3))
                await MainActor.run { showTitle = true }
            }

            // Phase 1.5 — ambient heartbeat loop
            Task {
                try? await Task.sleep(for: .seconds(1.3))
                while launchState == .checking {
                    await MainActor.run { heartbeatPhase.toggle() }
                    try? await Task.sleep(for: .seconds(1.8))
                }
            }

            // Phase 2 — status UI after 2.5s if still checking
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
                    // Icon with glow ring
                    ZStack {
                        // Ambient glow behind container
                        RadialGradient(
                            colors: [Color.tealStart.opacity(heartbeatPhase ? 0.20 : 0.12), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 90
                        )
                        .frame(width: 180, height: 180)
                        .blur(radius: 12)
                        .opacity(showIcon ? 1 : 0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.4), value: heartbeatPhase)

                        // Teal container
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.tealStart, Color.tealEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                            .warmShadowLg()
                            .scaleEffect(showIcon ? 1 : 0.5)
                            .opacity(showIcon ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showIcon)

                        // Heart icon
                        Image(systemName: "heart.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.white)
                            .scaleEffect(showHeart ? (heartbeatPhase ? 1.15 : 1.0) : 0.3)
                            .opacity(showHeart ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.65), value: showHeart)
                            .animation(.spring(response: 0.3, dampingFraction: 0.4), value: heartbeatPhase)
                    }

                    // Title
                    Text("Vivo")
                        .font(.system(size: 42, weight: .regular, design: .serif))
                        .foregroundStyle(Color.nearBlack)
                        .offset(y: showTitle ? 0 : 12)
                        .opacity(showTitle ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showTitle)

                    // Status UI
                    if statusVisible {
                        VStack(spacing: 12) {
                            PulsingDots()
                            Text("Looking for your data…")
                                .font(.system(size: 17))
                                .foregroundStyle(Color.mutedFg)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

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

private struct PulsingDots: View {
    @State private var activeDot = 0
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.primaryTeal)
                    .frame(width: 8, height: 8)
                    .scaleEffect(activeDot == i ? 1.4 : 0.8)
                    .opacity(activeDot == i ? 1.0 : 0.35)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: activeDot)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.5))
                activeDot = (activeDot + 1) % 3
            }
        }
    }
}
