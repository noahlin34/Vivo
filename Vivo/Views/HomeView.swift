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
    @Query(sort: \VitalRecord.recordedAt, order: .reverse) private var vitals: [VitalRecord]

    @State private var topSafeArea: CGFloat = 0
    @State private var selectedMed: Medication? = nil
    @State private var selectedAppt: Appointment? = nil
    @State private var selectedDoctor: Doctor? = nil
    @State private var selectedNote: HealthNote? = nil
    @State private var selectedVital: VitalRecord? = nil
    @State private var bannerDismissed: Bool = false
    @Environment(NotificationStatusMonitor.self) private var notificationStatus

    private var allUpcomingAppointments: [Appointment] {
        appointments.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }
    }
    private var upcomingAppointments: [Appointment] {
        allUpcomingAppointments.prefix(3).map { $0 }
    }

    private var nextAppointment: Appointment? { upcomingAppointments.first }

    private var scheduledMeds: [Medication] {
        medications.filter { $0.frequency != "As needed" }
    }
    private var todaysTakenCount: Int {
        scheduledMeds.filter { $0.isTakenToday }.count
    }
    private var todaysTotalCount: Int { scheduledMeds.count }
    private var todaysProgress: Double {
        guard todaysTotalCount > 0 else { return 0 }
        return Double(todaysTakenCount) / Double(todaysTotalCount)
    }
    private var progressLabel: String {
        if todaysTotalCount == 0 { return "No meds scheduled" }
        if todaysTakenCount == todaysTotalCount { return "All done for today!" }
        return "\(todaysTakenCount) of \(todaysTotalCount) taken"
    }

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
                MedicationNotifications.cancel(for: med)
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
        .sheet(item: $selectedDoctor) { doc in
            DoctorDetailSheet(doctor: doc) {
                modelContext.delete(doc)
                selectedDoctor = nil
            }
        }
        .sheet(item: $selectedNote) { note in
            NoteDetailSheet(note: note) {
                modelContext.delete(note)
                selectedNote = nil
            }
        }
        .sheet(item: $selectedVital) { vital in
            VitalDetailSheet(vital: vital) {
                modelContext.delete(vital)
                selectedVital = nil
            }
        }
        .onAppear {
            topSafeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                .windows.first?.safeAreaInsets.top ?? 0
            bannerDismissed = false
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
                    Spacer()
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

                // Medication progress card
                Button {
                    selectedTab = 1
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    medProgressCard
                }
                .buttonStyle(.plain)
                .padding(.top, 20)

                // Next appointment chip
                Button {
                    if let appt = nextAppointment {
                        selectedAppt = appt
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    heroChip(
                        icon: "calendar",
                        label: "Next Appointment",
                        value: nextAppointment.map { $0.date.formatted(.dateTime.month(.wide).day().hour().minute()) } ?? "None scheduled"
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
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

    var medProgressCard: some View {
        HStack(spacing: 16) {
            // Circular progress ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: CGFloat(todaysProgress))
                    .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: todaysProgress)

                if todaysTakenCount == todaysTotalCount && todaysTotalCount > 0 {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    VStack(spacing: -1) {
                        Text("\(todaysTakenCount)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                        Text("/\(todaysTotalCount)")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
            }
            .frame(width: 58, height: 58)

            // Labels + progress bar
            VStack(alignment: .leading, spacing: 5) {
                Text("Today's Medications")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.6))
                Text(progressLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 5)
                    Capsule()
                        .fill(.white)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: CGFloat(todaysProgress), anchor: .leading)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: todaysProgress)
                }
            }

            // Checkmark seal when complete
            if todaysTakenCount == todaysTotalCount && todaysTotalCount > 0 {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: .infinity)
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

    // MARK: - Notifications Banner

    var notificationsBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.amberStart)

            VStack(alignment: .leading, spacing: 2) {
                Text("Notifications Off")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.nearBlack)
                Text("Reminders won't be delivered")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mutedFg)
            }

            Spacer()

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Settings")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.amberStart)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.amberStart.opacity(0.12))
                    .clipShape(Capsule())
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    bannerDismissed = true
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.mutedFg)
                    .frame(width: 24, height: 24)
                    .background(Color.mutedBg)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.amberStart.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Main Content

    var mainContent: some View {
        VStack(spacing: 20) {
            // Notifications denied banner
            if notificationStatus.isDenied && !bannerDismissed {
                notificationsBanner
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Quick Pills
            quickPillsSection
                .padding(.horizontal, 20)
                .padding(.top, notificationStatus.isDenied && !bannerDismissed ? 0 : 16)

            // Today's Medications
            medsSection

            // Upcoming Appointments
            upcomingSection

            // Care Team Peek
            if !doctors.isEmpty {
                careTeamSection
            }

            // Recent Vitals
            if !vitals.isEmpty {
                recentVitalsSection
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
        HStack(spacing: 8) {
            quickPill(icon: "pill.fill", label: "Meds", count: medications.count,
                      gradient: [.tealStart, .tealEnd], tab: 1)
            quickPill(icon: "stethoscope", label: "Care", count: doctors.count + allUpcomingAppointments.count,
                      gradient: [.amberStart, .amberEnd], tab: 2)
            quickPill(icon: "waveform.path.ecg", label: "Vitals", count: vitals.count,
                      gradient: [.roseStart, .roseEnd], tab: 3)
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
                    .lineLimit(1)
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
                if medications.count > 3 {
                    Button {
                        selectedTab = 1
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 3) {
                            Text("See all")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(Color.primaryTeal)
                    }
                } else {
                    Text(todaysTotalCount > 0 ? "\(todaysTakenCount)/\(todaysTotalCount) taken" : "\(medications.count) active")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.primaryTeal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.primaryTeal.opacity(0.08))
                        .clipShape(Capsule())
                }
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
                if allUpcomingAppointments.count > 3 {
                    Button {
                        selectedTab = 2
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 3) {
                            Text("See all")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(Color.amberStart)
                    }
                } else {
                    Text("\(allUpcomingAppointments.count) appts")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.amberStart)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.amberStart.opacity(0.08))
                        .clipShape(Capsule())
                }
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
                Text("\(doctors.count) doctor\(doctors.count == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.tealEnd)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.tealEnd.opacity(0.08))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(doctors) { doc in
                        let style = SpecialtyStyle.forSpecialty(doc.specialty)
                        let initial = doc.name.split(separator: " ").last?.first.map(String.init) ?? "D"

                        Button { selectedDoctor = doc } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                ZStack {
                                    LinearGradient(colors: style.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                    Text(initial)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

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
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Recent Vitals

    var recentVitalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Vitals")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.nearBlack)
                Spacer()
                if vitals.count > 3 {
                    Button {
                        selectedTab = 3
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 3) {
                            Text("See all")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(Color.roseStart)
                    }
                } else {
                    Text("\(vitals.count) reading\(vitals.count == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.roseStart)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.roseStart.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(vitals.prefix(3)) { vital in
                    Button { selectedVital = vital } label: {
                        VitalCardRow(vital: vital)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Recent Notes

    var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Notes")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.nearBlack)
                Spacer()
                if notes.count > 2 {
                    Button {
                        selectedTab = 4
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 3) {
                            Text("See all")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(Color.purpleStart)
                    }
                } else {
                    Text("\(notes.count) note\(notes.count == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.purpleStart)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.purpleStart.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(notes.prefix(2)) { note in
                    let style = CategoryStyle.forCategory(note.category)
                    Button { selectedNote = note } label: {
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
                                .multilineTextAlignment(.leading)
                            Text(note.createdAt, format: .dateTime.month(.wide).day().year())
                                .font(.system(size: 11))
                                .foregroundStyle(Color.mutedFg.opacity(0.5))
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .warmShadow()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

}
