//
//  OnboardingView.swift
//  Vivo
//

import SwiftUI

// MARK: - Data model

private struct OnboardingPage {
    let icon: String
    let gradient: [Color]
    let title: String
    let body: String
    let isWelcome: Bool
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        icon: "",
        gradient: [Color.tealStart, Color.tealEnd],
        title: "Vivo",
        body: "Track medications, manage your care team, and stay on top of your health — all in one place.",
        isWelcome: true
    ),
    OnboardingPage(
        icon: "pill.fill",
        gradient: [Color.tealStart, Color.tealEnd],
        title: "Never miss a dose",
        body: "Log your medications with dosage and schedule. Get daily reminders so you never forget.",
        isWelcome: false
    ),
    OnboardingPage(
        icon: "stethoscope",
        gradient: [Color.amberStart, Color.amberEnd],
        title: "Your care team, organized",
        body: "Store your doctors' contact info and upcoming appointments. Tap to call or email directly.",
        isWelcome: false
    ),
    OnboardingPage(
        icon: "note.text",
        gradient: [Color.purpleStart, Color.purpleEnd],
        title: "Track how you feel",
        body: "Log symptoms, questions for your doctor, and health milestones — organized across six categories.",
        isWelcome: false
    ),
]

// MARK: - Per-page sub-view

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if page.isWelcome {
                welcomeContent
            } else {
                featureContent
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var welcomeContent: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                    .warmShadowLg()
                Image(systemName: "heart.fill")
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
    }

    private var featureContent: some View {
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
        }
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

    var body: some View {
        ZStack(alignment: .top) {
            Color.bg.ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(onboardingPages.indices, id: \.self) { i in
                    OnboardingPageView(page: onboardingPages[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Skip button (pages 2–4 only)
            if currentPage > 0 {
                HStack {
                    Spacer()
                    Button("Skip") {
                        withAnimation(.easeInOut(duration: 0.25)) { hasCompletedOnboarding = true }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.mutedFg)
                    .padding(.trailing, 24)
                    .padding(.top, 60)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomNavBar }
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
                Text(currentPage < onboardingPages.count - 1 ? "Next" : "Get Started")
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
