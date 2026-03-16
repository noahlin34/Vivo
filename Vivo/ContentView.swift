//
//  ContentView.swift
//  Vivo
//
//  Created by Noah Lin  on 2026-02-19.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        Group {
            switch selectedTab {
            case 0: HomeView(selectedTab: $selectedTab)
            case 1: MedicationsView()
            case 2: DoctorsView()
            case 3: AppointmentsView()
            case 4: VitalsView()
            case 5: NotesView()
            default: HomeView(selectedTab: $selectedTab)
            }
        }
        .tint(Color.primaryTeal)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

// MARK: - Custom Tab Bar

private struct TabItemDef {
    let icon: String
    let activeIcon: String
    let label: String
}

private let tabItems: [TabItemDef] = [
    .init(icon: "house",                activeIcon: "house.fill",              label: "Home"),
    .init(icon: "pill",                 activeIcon: "pill.fill",               label: "Meds"),
    .init(icon: "stethoscope",          activeIcon: "stethoscope",             label: "Doctors"),
    .init(icon: "calendar",             activeIcon: "calendar",                label: "Appts"),
    .init(icon: "waveform.path.ecg",    activeIcon: "waveform.path.ecg",       label: "Vitals"),
    .init(icon: "note.text",            activeIcon: "note.text",               label: "Notes"),
]

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        VStack(spacing: 0) {
            // Gradient fade above the bar (from bg to transparent going upward)
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
                // Frosted glass background that extends behind the home indicator
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

        Button {
            selectedTab = index
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    // Active glow background
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primaryTeal.opacity(isActive ? 0.1 : 0))
                        .frame(width: 36, height: 32)

                    Image(systemName: isActive ? item.activeIcon : item.icon)
                        .font(.system(size: 18, weight: isActive ? .medium : .light))
                        .foregroundStyle(isActive ? Color.primaryTeal : Color.mutedFg)
                }
                .frame(width: 38, height: 32)

                // Label only on active tab
                if isActive {
                    Text(item.label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.primaryTeal)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .offset(y: isActive ? -2 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
        }
        .buttonStyle(.plain)
    }
}
