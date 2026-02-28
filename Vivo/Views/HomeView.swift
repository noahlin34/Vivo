//
//  HomeView.swift
//  Vivo
//

import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Binding var selectedTab: Int
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medication.scheduledTime) private var medications: [Medication]
    @Query(sort: \Appointment.date) private var appointments: [Appointment]
    @Query private var doctors: [Doctor]
    @Query(sort: \HealthNote.createdAt, order: .reverse) private var notes: [HealthNote]

    @State private var topSafeArea: CGFloat = 0
    @State private var selectedMed: Medication? = nil
    @State private var selectedAppt: Appointment? = nil

    private var upcomingAppointments: [Appointment] {
        appointments.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }
            .prefix(3).map { $0 }
    }

    private var nextAppointment: Appointment? { upcomingAppointments.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                mainContent
            }
        }
        .background(Color.bg)
        .ignoresSafeArea(edges: .top)
        .sheet(item: $selectedMed) { med in
            MedicationDetailSheet(medication: med) {
                modelContext.delete(med)
                selectedMed = nil
            }
        }
        .sheet(item: $selectedAppt) { appt in
            AppointmentDetailSheet(appointment: appt) {
                AppointmentNotifications.cancel(for: appt)
                modelContext.delete(appt)
                selectedAppt = nil
            }
        }
        .onAppear {
            topSafeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                .windows.first?.safeAreaInsets.top ?? 0
        }
    }

    // MARK: - Hero

    var heroSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Date row
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, topSafeArea + 16)

                Text("My Health")
                    .font(.system(size: 32, weight: .regular, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.top, 4)

                Text("Your daily wellness overview")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 2)

                // Summary chips
                HStack(spacing: 10) {
                    heroChip(
                        icon: "pill.fill",
                        label: "Today's Meds",
                        value: "\(medications.count) active"
                    )
                    heroChip(
                        icon: "calendar",
                        label: "Next Appt",
                        value: nextAppointment.map { $0.date.formatted(.dateTime.month(.abbreviated).day()) } ?? "None"
                    )
                }
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 20)
        }
        .background {
            LinearGradient(
                colors: [Color(hex: "0D7C66"), Color(hex: "059669"), Color(hex: "0891B2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24))
            .ignoresSafeArea(edges: .top)
        }
    }

    func heroChip(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.6))
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Main Content

    var mainContent: some View {
        VStack(spacing: 20) {
            // Quick Pills
            quickPillsSection
                .padding(.horizontal, 20)
                .padding(.top, 16)

            // Today's Medications
            medsSection

            // Upcoming Appointments
            upcomingSection

            // Care Team Peek
            if !doctors.isEmpty {
                careTeamSection
            }

            // Recent Notes
            if !notes.isEmpty {
                recentNotesSection
            }

            Spacer(minLength: 100)
        }
    }

    // MARK: - Quick Pills

    var quickPillsSection: some View {
        HStack(spacing: 10) {
            quickPill(icon: "pill.fill", label: "Meds", count: medications.count,
                      gradient: [.tealStart, .tealEnd], tab: 1)
            quickPill(icon: "stethoscope", label: "Doctors", count: doctors.count,
                      gradient: [.amberStart, .amberEnd], tab: 2)
            quickPill(icon: "calendar", label: "Appts", count: appointments.count,
                      gradient: [.cyanStart, .cyanEnd], tab: 3)
            quickPill(icon: "doc.fill", label: "Notes", count: notes.count,
                      gradient: [.purpleStart, .purpleEnd], tab: 4)
        }
    }

    func quickPill(icon: String, label: String, count: Int, gradient: [Color], tab: Int) -> some View {
        Button {
            selectedTab = tab
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.nearBlack)
                Text("\(count)")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.mutedFg)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .warmShadowLg()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Today's Medications

    var medsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Medications")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.nearBlack)
                Spacer()
                Text("\(medications.count) total")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.primaryTeal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.primaryTeal.opacity(0.08))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            if medications.isEmpty {
                Text("No medications added yet. Tap Meds to add one.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.mutedFg)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(24)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .warmShadow()
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(medications.prefix(3)) { med in
                        Button { selectedMed = med } label: {
                            MedicationCardRow(medication: med)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Upcoming Appointments

    var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.nearBlack)
                Spacer()
                Text("\(upcomingAppointments.count) appts")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.amberStart)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.amberStart.opacity(0.08))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            if upcomingAppointments.isEmpty {
                Text("No upcoming appointments.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.mutedFg)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(24)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .warmShadow()
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(upcomingAppointments) { appt in
                        Button { selectedAppt = appt } label: {
                            AppointmentCardRow(appointment: appt, showTodayBadge: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Care Team

    var careTeamSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Care Team")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.nearBlack)
                Spacer()
                Text("\(doctors.count) doctors")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "059669"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "059669").opacity(0.08))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(doctors) { doc in
                        let style = SpecialtyStyle.forSpecialty(doc.specialty)
                        let initial = doc.name.split(separator: " ").last?.first.map(String.init) ?? "D"

                        VStack(alignment: .leading, spacing: 10) {
                            Text(initial)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    LinearGradient(colors: style.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                            Text(doc.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.nearBlack)
                                .lineLimit(1)
                            Text(doc.specialty)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.mutedFg)
                                .lineLimit(1)
                        }
                        .frame(width: 140)
                        .padding(16)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .warmShadow()
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Recent Notes

    var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Notes")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.nearBlack)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(notes.prefix(2)) { note in
                    let style = CategoryStyle.forCategory(note.category)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top) {
                            Text(note.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.nearBlack)
                                .lineLimit(1)
                            Spacer()
                            Text(note.category)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(style.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(style.color.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        Text(note.content)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mutedFg)
                            .lineLimit(2)
                        Text(note.createdAt, format: .dateTime.month(.wide).day().year())
                            .font(.system(size: 11))
                            .foregroundStyle(Color.mutedFg.opacity(0.5))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .warmShadow()
                }
            }
            .padding(.horizontal, 20)
        }
    }

}
