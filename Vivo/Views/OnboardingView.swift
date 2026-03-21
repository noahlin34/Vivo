//
//  OnboardingView.swift
//  Vivo
//

import SwiftUI
import UserNotifications

// MARK: - Progress Bar

private struct ProgressBar: View {
    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i <= currentPage ? Color.primaryTeal : Color.mutedBg)
                    .frame(height: 4)
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: currentPage)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Skip Warning Toast

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
    }
}

// MARK: - Page 0: Welcome

private struct WelcomePage: View {
    @State private var iconVisible = false
    @State private var titleVisible = false
    @State private var taglineVisible = false
    @State private var subtitleVisible = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 28) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(LinearGradient(colors: [Color.tealStart, Color.tealEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 100, height: 100)
                            .warmShadowLg()
                        Image(systemName: "heart.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                    }
                    .opacity(iconVisible ? 1 : 0)
                    .scaleEffect(iconVisible ? 1 : 0.7)

                    VStack(spacing: 12) {
                        Text("Vivo")
                            .font(.system(size: 48, weight: .regular, design: .serif))
                            .foregroundStyle(Color.nearBlack)
                            .opacity(titleVisible ? 1 : 0)
                            .offset(y: titleVisible ? 0 : 12)

                        Text("Your health, beautifully organized.")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.nearBlack)
                            .multilineTextAlignment(.center)
                            .opacity(taglineVisible ? 1 : 0)
                            .offset(y: taglineVisible ? 0 : 10)

                        Text("Track medications, vitals, appointments, and notes")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.mutedFg)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .opacity(subtitleVisible ? 1 : 0)
                            .offset(y: subtitleVisible ? 0 : 10)
                    }
                }
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
            .frame(minHeight: UIScreen.main.bounds.height - 200)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear { triggerStagger() }
    }

    private func triggerStagger() {
        iconVisible = false; titleVisible = false; taglineVisible = false; subtitleVisible = false
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.1)) { iconVisible = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.25)) { titleVisible = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.4)) { taglineVisible = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.55)) { subtitleVisible = true }
    }
}

// MARK: - Page 1: Privacy

private struct PrivacyCard: View {
    let icon: String
    let label: String
    let description: String
    let visible: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.tealStart, Color.tealEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.nearBlack)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.mutedFg)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .warmShadow()
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 20)
    }
}

private struct PrivacyPage: View {
    @State private var headerVisible = false
    @State private var card0Visible = false
    @State private var card1Visible = false
    @State private var card2Visible = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(LinearGradient(colors: [Color.tealStart, Color.tealEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 90, height: 90)
                            .warmShadowLg()
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(.white)
                    }
                    VStack(spacing: 10) {
                        Text("Your data stays yours.")
                            .font(.system(size: 28, weight: .regular, design: .serif))
                            .foregroundStyle(Color.nearBlack)
                            .multilineTextAlignment(.center)
                        Text("No account required. No servers. No tracking.")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.mutedFg)
                            .multilineTextAlignment(.center)
                    }
                }
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : 16)

                VStack(spacing: 12) {
                    PrivacyCard(
                        icon: "iphone",
                        label: "On-Device Storage",
                        description: "Everything lives on your iPhone",
                        visible: card0Visible
                    )
                    PrivacyCard(
                        icon: "wifi.slash",
                        label: "No Internet Required",
                        description: "Works completely offline",
                        visible: card1Visible
                    )
                    PrivacyCard(
                        icon: "hand.raised.fill",
                        label: "Zero Data Collection",
                        description: "We never see your health data",
                        visible: card2Visible
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear { triggerStagger() }
    }

    private func triggerStagger() {
        headerVisible = false; card0Visible = false; card1Visible = false; card2Visible = false
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.05)) { headerVisible = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.17)) { card0Visible = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.29)) { card1Visible = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.41)) { card2Visible = true }
    }
}

// MARK: - Page 2: Features

private struct FeatureGridCard: View {
    let icon: String
    let gradient: [Color]
    let title: String
    let description: String
    let visible: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.nearBlack)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mutedFg)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .warmShadow()
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 16)
    }
}

private struct FeaturesPage: View {
    @State private var titleVisible = false
    @State private var card0Visible = false
    @State private var card1Visible = false
    @State private var card2Visible = false
    @State private var card3Visible = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                Text("Everything you need")
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundStyle(Color.nearBlack)
                    .multilineTextAlignment(.center)
                    .opacity(titleVisible ? 1 : 0)
                    .offset(y: titleVisible ? 0 : 12)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    FeatureGridCard(
                        icon: "pill.fill",
                        gradient: [Color.tealStart, Color.tealEnd],
                        title: "Medications",
                        description: "Reminders, tracking, and refill alerts",
                        visible: card0Visible
                    )
                    FeatureGridCard(
                        icon: "stethoscope",
                        gradient: [Color.amberStart, Color.amberEnd],
                        title: "Care Team",
                        description: "Doctors, appointments, and contacts",
                        visible: card1Visible
                    )
                    FeatureGridCard(
                        icon: "waveform.path.ecg",
                        gradient: [Color.roseStart, Color.roseEnd],
                        title: "Vitals",
                        description: "Blood pressure, weight, and more",
                        visible: card2Visible
                    )
                    FeatureGridCard(
                        icon: "note.text",
                        gradient: [Color.purpleStart, Color.purpleEnd],
                        title: "Notes",
                        description: "Symptoms, questions, and health logs",
                        visible: card3Visible
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear { triggerStagger() }
    }

    private func triggerStagger() {
        titleVisible = false
        card0Visible = false; card1Visible = false; card2Visible = false; card3Visible = false
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.05)) { titleVisible = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.15)) { card0Visible = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.25)) { card1Visible = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.35)) { card2Visible = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.45)) { card3Visible = true }
    }
}

// MARK: - Page 3: Notifications

private struct NotificationsPage: View {
    @Binding var notificationsEnabled: Bool
    @State private var notificationsDenied: Bool = false
    @State private var headerVisible = false
    @State private var bodyVisible = false
    @State private var buttonVisible = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 28) {
                    VStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(LinearGradient(colors: [Color.tealStart, Color.tealEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 90, height: 90)
                                .warmShadowLg()
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(.white)
                        }
                        .opacity(headerVisible ? 1 : 0)
                        .scaleEffect(headerVisible ? 1 : 0.8)

                        VStack(spacing: 10) {
                            Text("Stay on track")
                                .font(.system(size: 28, weight: .regular, design: .serif))
                                .foregroundStyle(Color.nearBlack)
                                .multilineTextAlignment(.center)
                            Text("Get reminders for medications and upcoming appointments.")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.mutedFg)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                        .opacity(bodyVisible ? 1 : 0)
                        .offset(y: bodyVisible ? 0 : 10)
                    }

                    VStack(spacing: 12) {
                        Button {
                            if notificationsDenied {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } else {
                                UNUserNotificationCenter.current()
                                    .requestAuthorization(options: [.alert, .sound]) { granted, _ in
                                        DispatchQueue.main.async {
                                            notificationsEnabled = granted
                                            if !granted { notificationsDenied = true }
                                        }
                                    }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if notificationsEnabled {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 15, weight: .semibold))
                                } else if notificationsDenied {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                Text(notificationsEnabled ? "Notifications Enabled" : notificationsDenied ? "Open Settings" : "Enable Notifications")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background {
                                if notificationsEnabled {
                                    Color.mutedFg
                                } else if notificationsDenied {
                                    LinearGradient(colors: [Color.amberStart, Color.amberEnd], startPoint: .leading, endPoint: .trailing)
                                } else {
                                    LinearGradient(colors: [Color.tealStart, Color.tealEnd], startPoint: .leading, endPoint: .trailing)
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
                    .opacity(buttonVisible ? 1 : 0)
                    .offset(y: buttonVisible ? 0 : 10)
                }
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(minHeight: UIScreen.main.bounds.height - 200)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            checkNotificationStatus()
            triggerStagger()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { checkNotificationStatus() }
        }
    }

    private func triggerStagger() {
        headerVisible = false; bodyVisible = false; buttonVisible = false
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.1)) { headerVisible = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.25)) { bodyVisible = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.4)) { buttonVisible = true }
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
                notificationsDenied = settings.authorizationStatus == .denied
            }
        }
    }
}

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentPage: Int = 0
    @State private var goingForward: Bool = true
    @State private var notificationsEnabled: Bool = false
    @State private var showSkipWarning: Bool = false
    @State private var skipWarningShown: Bool = false
    @State private var topSafeArea: CGFloat = 0

    private let totalPages = 4
    private var isLastPage: Bool { currentPage == totalPages - 1 }

    var body: some View {
        ZStack(alignment: .top) {
            Color.bg.ignoresSafeArea()

            // Page content
            ZStack {
                pageContent
                    .id(currentPage)
                    .transition(.asymmetric(
                        insertion: .move(edge: goingForward ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: goingForward ? .leading : .trailing).combined(with: .opacity)
                    ))
            }
            .padding(.top, topSafeArea + 60)

            // Top chrome: back + skip
            HStack {
                if currentPage > 0 {
                    Button {
                        goingForward = false
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            currentPage -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.mutedFg)
                            .frame(width: 36, height: 36)
                    }
                    .transition(.opacity)
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }

                Spacer()

                if currentPage > 0 {
                    Button("Skip") { handleSkip() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.mutedFg)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, topSafeArea + 12)
            .animation(.easeInOut(duration: 0.2), value: currentPage)

            // Two-tap skip warning toast
            if showSkipWarning {
                SkipWarningToast()
                    .padding(.top, topSafeArea + 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .onAppear {
            topSafeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                .windows.first?.safeAreaInsets.top ?? 0
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch currentPage {
        case 0:
            WelcomePage()
        case 1:
            PrivacyPage()
        case 2:
            FeaturesPage()
        case 3:
            NotificationsPage(notificationsEnabled: $notificationsEnabled)
        default:
            EmptyView()
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 16) {
            ProgressBar(totalPages: totalPages, currentPage: currentPage)

            Button {
                if !isLastPage {
                    goingForward = true
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        currentPage += 1
                    }
                } else {
                    attemptCompleteOnboarding()
                }
            } label: {
                Text(isLastPage ? "Get Started" : "Next")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(colors: [Color.tealStart, Color.tealEnd], startPoint: .leading, endPoint: .trailing)
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

    private func attemptCompleteOnboarding() {
        if !notificationsEnabled && !skipWarningShown {
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

    private func handleSkip() {
        if !notificationsEnabled && !skipWarningShown && !isLastPage {
            skipWarningShown = true
            goingForward = true
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showSkipWarning = true }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                currentPage = totalPages - 1
            }
            Task {
                try? await Task.sleep(for: .seconds(4))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showSkipWarning = false }
            }
        } else {
            attemptCompleteOnboarding()
        }
    }
}
