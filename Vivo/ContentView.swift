//
//  ContentView.swift
//  Vivo
//
//  Created by Noah Lin  on 2026-02-19.
//

import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var notificationStatus = NotificationStatusMonitor()
    @State private var walkthrough = WalkthroughManager()
    @AppStorage("hasCompletedWalkthrough") private var hasCompletedWalkthrough = false
    @Environment(\.scenePhase) private var scenePhase
    @Query private var medications: [Medication]
    @Query private var appointments: [Appointment]

    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab).tag(0)
            MedicationsView().tag(1)
            CareView().tag(2)
            VitalsView().tag(3)
            NotesView().tag(4)
        }
        .environment(notificationStatus)
        .environment(walkthrough)
        .tint(Color.primaryTeal)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab)
        }
        .overlay {
            SpotlightOverlay()
        }
        .onAppear {
            rescheduleAllNotifications()
            notificationStatus.refresh()
            if !hasCompletedWalkthrough {
                if medications.isEmpty {
                    walkthrough.isActive = true
                } else {
                    hasCompletedWalkthrough = true
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { notificationStatus.refresh() }
        }
    }

    private func rescheduleAllNotifications() {
        for med in medications {
            MedicationNotifications.schedule(for: med)
        }
        let now = Date()
        for appt in appointments where appt.date > now {
            AppointmentNotifications.schedule(for: appt)
        }
    }
}

// MARK: - Custom Tab Bar

private struct TabItemDef {
    let icon: String
    let activeIcon: String
    let label: String
    let color: Color
}

private let tabItems: [TabItemDef] = [
    .init(icon: "house",             activeIcon: "house.fill",         label: "Home",   color: .primaryTeal),
    .init(icon: "pill",              activeIcon: "pill.fill",          label: "Meds",   color: .tealStart),
    .init(icon: "stethoscope",       activeIcon: "stethoscope",        label: "Care",   color: .amberStart),
    .init(icon: "waveform.path.ecg", activeIcon: "waveform.path.ecg",  label: "Vitals", color: .roseStart),
    .init(icon: "note.text",         activeIcon: "note.text",          label: "Notes",  color: .purpleStart),
]

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Environment(WalkthroughManager.self) private var walkthrough

    var body: some View {
        VStack(spacing: 0) {
            // Gradient fade above the bar
            LinearGradient(
                colors: [Color.bg.opacity(0), Color.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            // Tab buttons
            HStack(spacing: 0) {
                ForEach(tabItems.indices, id: \.self) { index in
                    tabButton(index: index)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 8)
            .background {
                Color.cardBg.opacity(0.7)
                    .background(.ultraThinMaterial)
                    .overlay(alignment: .top) {
                        Color.cardBg.opacity(0.3).frame(height: 0.5)
                    }
                    .shadow(color: Color(hex: "1A1612").opacity(0.06), radius: 12, x: 0, y: -4)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    @ViewBuilder
    private func tabButton(index: Int) -> some View {
        let item = tabItems[index]
        let isActive = selectedTab == index
        let isMedsTarget = walkthrough.isActive && walkthrough.currentStep == .tapMedsTab && index == 1
        let isBlocked = walkthrough.isActive && walkthrough.currentStep == .tapMedsTab && index != 1

        Button {
            guard !isBlocked else { return }
            selectedTab = index
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if isMedsTarget {
                walkthrough.advance()
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    // Active glow background
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(item.color.opacity(isActive ? 0.1 : 0))
                        .frame(width: 36, height: 32)

                    Image(systemName: isActive ? item.activeIcon : item.icon)
                        .font(.system(size: 18, weight: isActive ? .medium : .light))
                        .foregroundStyle(isActive ? item.color : Color.mutedFg)
                }
                .frame(width: 38, height: 32)
                // Report Meds tab frame for spotlight
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { newFrame in
                    if index == 1 {
                        walkthrough.medsTabFrame = newFrame
                    }
                }

                // Label only on active tab
                if isActive {
                    Text(item.label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(item.color)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .offset(y: isActive ? -2 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            // Dim non-target tabs during walkthrough
            .opacity(isBlocked ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: walkthrough.isActive)
        }
        .buttonStyle(.plain)
    }
}
