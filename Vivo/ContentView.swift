//
//  ContentView.swift
//  Vivo
//
//  Created by Noah Lin  on 2026-02-19.
//

import SwiftUI
import UIKit

struct ContentView: View {
    init() {
        // Tab bar: warm cream background, teal active tint
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        // #F6F2EC = rgb(246, 242, 236)
        appearance.backgroundColor = UIColor(red: 246/255, green: 242/255, blue: 236/255, alpha: 0.97)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                HomeView()
            }
            Tab("Meds", systemImage: "pill.fill") {
                MedicationsView()
            }
            Tab("Doctors", systemImage: "stethoscope") {
                DoctorsView()
            }
            Tab("Appts", systemImage: "calendar") {
                AppointmentsView()
            }
            Tab("Notes", systemImage: "note.text") {
                NotesView()
            }
        }
        .tint(Color(hex: "0D7C66"))
    }
}
