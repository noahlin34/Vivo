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

    init() {
        // Hide the system tab bar — we render our own custom one
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView().tag(0)
            MedicationsView().tag(1)
            DoctorsView().tag(2)
            AppointmentsView().tag(3)
            NotesView().tag(4)
        }
        .tint(Color(hex: "0D7C66"))
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
    .init(icon: "house",       activeIcon: "house.fill",  label: "Home"),
    .init(icon: "pill",        activeIcon: "pill.fill",   label: "Meds"),
    .init(icon: "stethoscope", activeIcon: "stethoscope", label: "Doctors"),
    .init(icon: "calendar",    activeIcon: "calendar",    label: "Appts"),
    .init(icon: "note.text",   activeIcon: "note.text",   label: "Notes"),
]

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        VStack(spacing: 0) {
            // Gradient fade above the bar (from bg to transparent going upward)
            LinearGradient(
                colors: [Color(hex: "F6F2EC").opacity(0), Color(hex: "F6F2EC")],
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
                Color.white.opacity(0.7)
                    .background(.ultraThinMaterial)
                    .overlay(alignment: .top) {
                        Color.white.opacity(0.3).frame(height: 0.5)
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
            VStack(spacing: 2) {
                ZStack {
                    // Active glow background
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: "0D7C66").opacity(isActive ? 0.1 : 0))
                        .frame(width: 40, height: 36)

                    Image(systemName: isActive ? item.activeIcon : item.icon)
                        .font(.system(size: 22, weight: isActive ? .medium : .light))
                        .foregroundStyle(isActive ? Color(hex: "0D7C66") : Color(hex: "8C8279"))
                }
                .frame(width: 44, height: 36)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)

                Text(item.label)
                    .font(.system(size: 10))
                    .foregroundStyle(isActive ? Color(hex: "0D7C66") : Color(hex: "8C8279"))

                // Active dot
                Circle()
                    .fill(isActive ? Color(hex: "0D7C66") : Color.clear)
                    .frame(width: 4, height: 4)
                    .padding(.top, 2)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .offset(y: isActive ? -2 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
        }
        .buttonStyle(.plain)
    }
}
