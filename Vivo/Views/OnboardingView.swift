//
//  OnboardingView.swift
//  Vivo
//

import SwiftUI
import SwiftData

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

// MARK: - Onboarding Add Medication

private struct OnboardingAddMedicationView: View {
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = "Once daily"
    @State private var scheduledTime  = Calendar.current.date(bySettingHour:  8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var scheduledTime2 = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var scheduledTime3 = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var enableReminder = true

    private let frequencies = ["Once daily", "Twice daily", "Three times daily", "As needed"]

    private var nameIsEmpty: Bool { name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Add your first medication")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundStyle(Color.nearBlack)
                Text("You can always add more later.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.mutedFg)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .padding(.horizontal, 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    FormSection(title: "Info") {
                        FormTextField(label: "Name", text: $name, placeholder: "Medication name", icon: "pill.fill")
                        FormTextField(label: "Dosage", text: $dosage, placeholder: "e.g. 10mg", icon: "scalemass.fill")
                    }
                    FormSection(title: "Schedule") {
                        FormChipPicker(
                            selection: $frequency,
                            options: frequencies,
                            labels: { $0 == "Three times daily" ? "3× daily" : $0 },
                            gradient: [.tealStart, .tealEnd]
                        )
                        if frequency != "As needed" {
                            medicationTimePickerRow(
                                label: frequency == "Once daily" ? "Time" : "Dose 1",
                                selection: $scheduledTime
                            )
                            if frequency == "Twice daily" || frequency == "Three times daily" {
                                medicationTimePickerRow(label: "Dose 2", selection: $scheduledTime2)
                            }
                            if frequency == "Three times daily" {
                                medicationTimePickerRow(label: "Dose 3", selection: $scheduledTime3)
                            }
                            HStack(spacing: 10) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.primaryTeal)
                                    .frame(width: 20)
                                Text("Remind me")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.nearBlack)
                                Spacer()
                                Toggle("", isOn: $enableReminder)
                                    .labelsHidden()
                                    .tint(Color.primaryTeal)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.mutedBg.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)

            VStack(spacing: 12) {
                Button(action: save) {
                    Text("Add Medication")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background {
                            if nameIsEmpty {
                                Color.mutedFg.opacity(0.35)
                            } else {
                                LinearGradient(colors: [Color.tealStart, Color.tealEnd], startPoint: .leading, endPoint: .trailing)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .warmShadow()
                }
                .buttonStyle(.plain)
                .disabled(nameIsEmpty)

                Button("Skip for now", action: onComplete)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.mutedFg)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
    }

    private func save() {
        let med = Medication(
            name: name.trimmingCharacters(in: .whitespaces),
            dosage: dosage.trimmingCharacters(in: .whitespaces),
            frequency: frequency,
            scheduledTime: scheduledTime,
            colorIndex: 0,
            notes: ""
        )
        med.reminderOffset = (frequency != "As needed" && enableReminder) ? 0 : -1
        med.scheduledTime2 = (frequency == "Twice daily" || frequency == "Three times daily") ? scheduledTime2 : nil
        med.scheduledTime3 = frequency == "Three times daily" ? scheduledTime3 : nil
        modelContext.insert(med)
        MedicationNotifications.schedule(for: med)
        onComplete()
    }
}

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showMedicationForm = false
    @State private var topSafeArea: CGFloat = 0

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()

            if showMedicationForm {
                OnboardingAddMedicationView(onComplete: complete)
                    .padding(.top, topSafeArea + 20)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                WelcomePage(onGetStarted: {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        showMedicationForm = true
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            topSafeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                .windows.first?.safeAreaInsets.top ?? 0
        }
    }

    private func complete() {
        withAnimation(.easeInOut(duration: 0.25)) {
            hasCompletedOnboarding = true
        }
    }
}
