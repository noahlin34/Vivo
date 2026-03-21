//
//  CareView.swift
//  Vivo
//

import SwiftUI
import SwiftData
import UserNotifications

struct CareView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Doctor.createdAt) private var doctors: [Doctor]
    @Query(sort: \Appointment.date) private var appointments: [Appointment]
    @State private var searchText = ""
    @State private var showAddDoctor = false
    @State private var showAddAppointment = false
    @State private var selectedDoctor: Doctor? = nil
    @State private var selectedAppointment: Appointment? = nil
    @State private var doctorToDelete: Doctor? = nil

    private var filteredDoctors: [Doctor] {
        guard !searchText.isEmpty else { return doctors }
        return doctors.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.specialty.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var allUpcoming: [Appointment] {
        appointments.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }
    }

    private var allPast: [Appointment] {
        Array(appointments.filter { $0.date < Calendar.current.startOfDay(for: Date()) }.reversed())
    }

    private var filteredUpcoming: [Appointment] {
        guard !searchText.isEmpty else { return allUpcoming }
        return allUpcoming.filter { matchesSearch($0) }
    }

    private var filteredPast: [Appointment] {
        guard !searchText.isEmpty else { return allPast }
        return allPast.filter { matchesSearch($0) }
    }

    private func matchesSearch(_ appt: Appointment) -> Bool {
        appt.title.localizedCaseInsensitiveContains(searchText) ||
        appt.displayDoctorName.localizedCaseInsensitiveContains(searchText) ||
        appt.location.localizedCaseInsensitiveContains(searchText)
    }

    private var isEmpty: Bool { doctors.isEmpty && appointments.isEmpty }
    private var noResults: Bool {
        !searchText.isEmpty && filteredDoctors.isEmpty && filteredUpcoming.isEmpty && filteredPast.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Care")
                            .font(.system(size: 28, weight: .regular, design: .serif))
                            .foregroundStyle(Color.nearBlack)
                        Text("\(doctors.count) doctor\(doctors.count == 1 ? "" : "s") · \(allUpcoming.count) upcoming")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mutedFg)
                    }
                    Spacer()
                    Menu {
                        Button { showAddAppointment = true } label: {
                            Label("Add Appointment", systemImage: "calendar.badge.plus")
                        }
                        Button { showAddDoctor = true } label: {
                            Label("Add Doctor", systemImage: "stethoscope")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                LinearGradient(colors: [.amberStart, .amberEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 20)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.mutedFg.opacity(0.6))
                    TextField("Search care team...", text: $searchText)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .warmShadow()
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Content
                if isEmpty {
                    emptyState
                } else if noResults {
                    Text("No results for \"\(searchText)\"")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.mutedFg)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(24)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .warmShadow()
                        .padding(.horizontal, 20)
                } else {
                    VStack(spacing: 20) {
                        // Upcoming appointments
                        if !filteredUpcoming.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionLabel(title: "Upcoming", dotColor: Color.primaryTeal)
                                    .padding(.horizontal, 20)

                                VStack(spacing: 10) {
                                    ForEach(filteredUpcoming) { appt in
                                        Button { selectedAppointment = appt } label: {
                                            AppointmentCardRow(appointment: appt, showTodayBadge: true)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // Care Team
                        if !filteredDoctors.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionLabel(title: "Care Team", dotColor: Color.amberStart)
                                    .padding(.horizontal, 20)

                                VStack(spacing: 12) {
                                    ForEach(filteredDoctors) { doc in
                                        Button { selectedDoctor = doc } label: {
                                            DoctorCardRow(doctor: doc)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // Past appointments
                        if !filteredPast.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionLabel(title: "Past", dotColor: Color.mutedFg.opacity(0.4))
                                    .padding(.horizontal, 20)

                                VStack(spacing: 10) {
                                    ForEach(filteredPast) { appt in
                                        Button { selectedAppointment = appt } label: {
                                            AppointmentCardRow(appointment: appt)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }

                Spacer(minLength: 100)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.bg)
        .sheet(isPresented: $showAddDoctor) { AddDoctorView() }
        .sheet(isPresented: $showAddAppointment) { AddAppointmentView() }
        .sheet(item: $selectedDoctor) { doc in
            DoctorDetailSheet(doctor: doc) {
                modelContext.delete(doc)
                selectedDoctor = nil
            }
        }
        .sheet(item: $selectedAppointment) { appt in
            AppointmentDetailSheet(appointment: appt) {
                AppointmentNotifications.cancel(for: appt)
                modelContext.delete(appt)
                selectedAppointment = nil
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "stethoscope")
                .font(.system(size: 28))
                .foregroundStyle(Color.amberStart.opacity(0.4))
                .frame(width: 64, height: 64)
                .background(Color.amberStart.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            Text("No doctors or appointments yet")
                .font(.system(size: 15))
                .foregroundStyle(Color.mutedFg)
            Text("Tap + to get started")
                .font(.system(size: 13))
                .foregroundStyle(Color.mutedFg.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .warmShadow()
        .padding(.horizontal, 20)
    }
}
