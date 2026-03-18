//
//  WelcomeBackView.swift
//  Vivo
//

import SwiftUI

struct WelcomeBackView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.cyanStart, Color.cyanEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                            .warmShadowLg()
                        Image(systemName: "icloud.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 12) {
                        Text("Welcome back")
                            .font(.system(size: 42, weight: .regular, design: .serif))
                            .foregroundStyle(Color.nearBlack)
                            .multilineTextAlignment(.center)
                        Text("We found your health data in iCloud and it's ready to go.")
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text("Continue")
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
}
