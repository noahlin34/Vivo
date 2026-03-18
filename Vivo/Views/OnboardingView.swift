//
//  OnboardingView.swift
//  Vivo
//

import SwiftUI
import UserNotifications

// MARK: - Data model

private enum PageKind { case welcome, feature, notification }

private struct FeatureBullet {
    let icon: String
    let text: String
}

private struct OnboardingPage {
    let icon: String
    let gradient: [Color]
    let title: String
    let body: String
    let bullets: [FeatureBullet]
    let kind: PageKind
}

private let onboardingPages: [OnboardingPage] = [
    // 0 — Welcome
    OnboardingPage(
        icon: "heart.fill",
        gradient: [Color.tealStart, Color.tealEnd],
        title: "Vivo",
        body: "Your medications, doctors, vitals, and health notes — all in one private, synced place.",
        bullets: [],
        kind: .welcome
    ),
    // 1 — Medications
    OnboardingPage(
        icon: "pill.fill",
        gradient: [Color.tealStart, Color.tealEnd],
        title: "Never miss a dose",
        body: "",
        bullets: [
            FeatureBullet(icon: "bell.fill", text: "Schedule daily reminders for each medication"),
            FeatureBullet(icon: "pills.fill", text: "Track pill supply with low-refill warnings"),
            FeatureBullet(icon: "checkmark.circle.fill", text: "Tap to log doses and view 7-day adherence"),
        ],
        kind: .feature
    ),
    // 2 — Care Team
    OnboardingPage(
        icon: "stethoscope",
        gradient: [Color.amberStart, Color.amberEnd],
        title: "Your care team, organized",
        body: "",
        bullets: [
            FeatureBullet(icon: "person.crop.circle.fill", text: "Save doctor contact info by specialty"),
            FeatureBullet(icon: "calendar.badge.clock", text: "Track appointments with timely reminders"),
            FeatureBullet(icon: "phone.fill", text: "Tap to call or email directly from the app"),
        ],
        kind: .feature
    ),
    // 3 — Vitals (new)
    OnboardingPage(
        icon: "waveform.path.ecg",
        gradient: [Color.roseStart, Color.roseEnd],
        title: "Monitor your vitals",
        body: "",
        bullets: [
            FeatureBullet(icon: "staroflife.fill", text: "Log blood pressure, weight, heart rate, and blood sugar"),
            FeatureBullet(icon: "chart.line.uptrend.xyaxis", text: "View 30-day trend charts for each vital type"),
            FeatureBullet(icon: "heart.fill", text: "Import readings directly from Apple Health"),
        ],
        kind: .feature
    ),
    // 4 — Notes
    OnboardingPage(
        icon: "note.text",
        gradient: [Color.purpleStart, Color.purpleEnd],
        title: "Track how you feel",
        body: "",
        bullets: [
            FeatureBullet(icon: "square.and.pencil", text: "Log symptoms, questions, and health milestones"),
            FeatureBullet(icon: "square.grid.2x2.fill", text: "Organize notes across six categories"),
            FeatureBullet(icon: "magnifyingglass", text: "Search and filter to find what you need"),
        ],
        kind: .feature
    ),
    // 5 — Notifications
    OnboardingPage(
        icon: "bell.badge.fill",
        gradient: [Color.tealStart, Color.tealEnd],
        title: "Stay on track",
        body: "Allow notifications so Vivo can remind you to take medications and alert you before appointments.",
        bullets: [],
        kind: .notification
    ),
]

// MARK: - Feature bullet row

private struct FeatureBulletRow: View {
    let bullet: FeatureBullet
    let gradient: [Color]

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                Image(systemName: bullet.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text(bullet.text)
                .font(.system(size: 15))
                .foregroundStyle(Color.nearBlack)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

// MARK: - Skip warning toast

private struct SkipWarningToast: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.amberStart)
            Text("Notifications help you stay on track with medications and appointments.")
                .font(.system(size: 13))
                .foregroundStyle(Color.nearBlack)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .warmShadow()
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
}

// MARK: - Per-page sub-view

private struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var notificationsEnabled: Bool

    var body: some View {
        Group {
            if page.kind == .welcome {
                welcomeLayout
            } else if page.kind == .notification {
                notificationLayout
            } else {
                featureLayout
            }
        }
    }

    private var welcomeLayout: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                        .warmShadowLg()
                    Image(systemName: page.icon)
                        .font(.system(size: 52))
                        .foregroundStyle(.white)
                }
                VStack(spacing: 12) {
                    Text(page.title)
                        .font(.system(size: 42, weight: .regular, design: .serif))
                        .foregroundStyle(Color.nearBlack)
                        .multilineTextAlignment(.center)
                    Text(page.body)
                        .font(.system(size: 17))
                        .foregroundStyle(Color.mutedFg)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var featureLayout: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 104, height: 104)
                        .warmShadowLg()
                    Image(systemName: page.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                }
                Text(page.title)
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundStyle(Color.nearBlack)
                    .multilineTextAlignment(.center)
                VStack(spacing: 14) {
                    ForEach(page.bullets.indices, id: \.self) { i in
                        FeatureBulletRow(bullet: page.bullets[i], gradient: page.gradient)
                    }
                }
                .padding(20)
                .background(Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .warmShadow()
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var notificationLayout: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 104, height: 104)
                        .warmShadowLg()
                    Image(systemName: page.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                }
                VStack(spacing: 12) {
                    Text(page.title)
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .foregroundStyle(Color.nearBlack)
                        .multilineTextAlignment(.center)
                    Text(page.body)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.mutedFg)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                VStack(spacing: 12) {
                    Button {
                        UNUserNotificationCenter.current()
                            .requestAuthorization(options: [.alert, .sound]) { granted, _ in
                                DispatchQueue.main.async { notificationsEnabled = granted }
                            }
                    } label: {
                        HStack(spacing: 8) {
                            if notificationsEnabled {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            Text(notificationsEnabled ? "Notifications Enabled" : "Enable Notifications")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background {
                            if notificationsEnabled {
                                Color.mutedFg
                            } else {
                                LinearGradient(colors: page.gradient, startPoint: .leading, endPoint: .trailing)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .warmShadow()
                    }
                    .buttonStyle(.plain)
                    .disabled(notificationsEnabled)

                    Text("You can change this later in Settings")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.mutedFg)
                }
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Animated dot indicator

private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.primaryTeal : Color.mutedBg)
                    .frame(width: i == current ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: current)
            }
        }
    }
}

// MARK: - Main view

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentPage: Int = 0
    @State private var notificationsEnabled: Bool = false
    @State private var showSkipWarning: Bool = false
    @State private var skipWarningShown: Bool = false

    private var isLastPage: Bool { currentPage == onboardingPages.count - 1 }

    var body: some View {
        ZStack(alignment: .top) {
            Color.bg.ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(onboardingPages.indices, id: \.self) { i in
                    OnboardingPageView(page: onboardingPages[i], notificationsEnabled: $notificationsEnabled)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Skip button (pages 1–6 only)
            if currentPage > 0 {
                HStack {
                    Spacer()
                    Button("Skip") { handleSkip() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.mutedFg)
                        .padding(.trailing, 24)
                        .padding(.top, 60)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: currentPage)
            }

            // Two-tap skip warning toast
            if showSkipWarning {
                SkipWarningToast()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomNavBar }
    }

    private func handleSkip() {
        if isLastPage && !skipWarningShown {
            skipWarningShown = true
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showSkipWarning = true }
            Task {
                try? await Task.sleep(for: .seconds(4))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showSkipWarning = false }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { hasCompletedOnboarding = true }
        }
    }

    private var bottomNavBar: some View {
        VStack(spacing: 20) {
            PageDots(count: onboardingPages.count, current: currentPage)
            Button {
                if currentPage < onboardingPages.count - 1 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { currentPage += 1 }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) { hasCompletedOnboarding = true }
                }
            } label: {
                Text(isLastPage ? "Get Started" : "Next")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.tealStart, Color.tealEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .warmShadow()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
        }
        .padding(.top, 16)
        .padding(.bottom, 40)
        .background(Color.bg)
    }
}
