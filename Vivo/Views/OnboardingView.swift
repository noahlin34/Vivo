//
//  OnboardingView.swift
//  Vivo
//

import SwiftUI

// MARK: - Welcome Page

private struct WelcomePage: View {
    let onGetStarted: () -> Void

    @State private var iconVisible = false
    @State private var titleVisible = false
    @State private var taglineVisible = false
    @State private var privacyVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
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

                    Text("Track medications, appointments, vitals,\nand notes — all in one place.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mutedFg)
                        .multilineTextAlignment(.center)
                        .opacity(taglineVisible ? 1 : 0)
                        .offset(y: taglineVisible ? 0 : 10)
                }

                Button(action: onGetStarted) {
                    Text("Get Started")
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
                .opacity(taglineVisible ? 1 : 0)
                .offset(y: taglineVisible ? 0 : 10)
            }
            .padding(.horizontal, 32)

            Spacer()

            Text("Your data stays on your device. Always.")
                .font(.system(size: 13))
                .foregroundStyle(Color.mutedFg)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(privacyVisible ? 1 : 0)
        }
        .onAppear { triggerStagger() }
    }

    private func triggerStagger() {
        iconVisible = false; titleVisible = false; taglineVisible = false; privacyVisible = false
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.1))  { iconVisible    = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.25)) { titleVisible   = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.4))  { taglineVisible = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.55)) { privacyVisible = true }
    }
}

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            WelcomePage {
                withAnimation(.easeInOut(duration: 0.25)) {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
