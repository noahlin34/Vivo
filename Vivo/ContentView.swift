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
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab).tag(0)
            MedicationsView().tag(1)
            DoctorsView().tag(2)
            AppointmentsView().tag(3)
            VitalsView().tag(4)
            NotesView().tag(5)
        }
        .background(MoreNavBarHider())
        .tint(Color.primaryTeal)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

// MARK: - Hide "More" Navigation Bar

/// With 6+ tabs, UIKit's UITabBarController creates a "More" navigation
/// controller for overflow tabs, producing a back button even though the
/// system tab bar is hidden. This walks the responder chain to find the
/// tab bar controller and hides that navigation bar directly.
private struct MoreNavBarHider: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async { hideMoreBar(from: view) }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async { hideMoreBar(from: uiView) }
    }

    private func hideMoreBar(from view: UIView) {
        var responder: UIResponder? = view
        while let next = responder?.next {
            if let tabController = next as? UITabBarController {
                tabController.moreNavigationController.isNavigationBarHidden = true
                return
            }
            responder = next
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
    .init(icon: "house",             activeIcon: "house.fill",         label: "Home",    color: .primaryTeal),
    .init(icon: "pill",              activeIcon: "pill.fill",          label: "Meds",    color: .tealStart),
    .init(icon: "stethoscope",       activeIcon: "stethoscope",        label: "Doctors", color: .amberStart),
    .init(icon: "calendar",          activeIcon: "calendar",           label: "Appts",   color: .cyanStart),
    .init(icon: "waveform.path.ecg", activeIcon: "waveform.path.ecg",  label: "Vitals",  color: .roseStart),
    .init(icon: "note.text",         activeIcon: "note.text",          label: "Notes",   color: .purpleStart),
]

struct CustomTabBar: View {
    @Binding var selectedTab: Int

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

        Button {
            selectedTab = index
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
        }
        .buttonStyle(.plain)
    }
}
