//
//  AppointmentsView.swift
//  Vivo
//

import SwiftUI
import SwiftData

struct AppointmentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Appointment.date) private var appointments: [Appointment]
    @State private var showAdd = false
    @State private var selected: Appointment? = nil

    private var upcoming: [Appointment] {
        appointments.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }
    }
    private var past: [Appointment] {
        appointments.filter { $0.date < Calendar.current.startOfDay(for: Date()) }.reversed()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Appointments")
                            .font(.system(size: 28, weight: .regular, design: .serif))
                            .foregroundStyle(Color.nearBlack)
                        Text("\(upcoming.count) upcoming · \(past.count) past")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mutedFg)
                    }
                    Spacer()
                    GradientAddButton(gradient: [.cyanStart, .cyanEnd]) { showAdd = true }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)

                if appointments.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 20) {
                        if !upcoming.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionLabel(title: "Upcoming", dotColor: Color.primaryTeal)
                                    .padding(.horizontal, 20)

                                VStack(spacing: 0) {
                                    ForEach(Array(upcoming.enumerated()), id: \.element.id) { index, appt in
                                        let isToday = Calendar.current.isDateInToday(appt.date)
                                        Button { selected = appt } label: {
                                            VStack(spacing: 0) {
                                                if isToday {
                                                    LinearGradient(colors: [.amberStart, .amberEnd], startPoint: .leading, endPoint: .trailing)
                                                        .frame(height: 3)
                                                }
                                                AppointmentCardRow(appointment: appt)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) { modelContext.delete(appt) } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        if index < upcoming.count - 1 {
                                            Divider().padding(.leading, 82)
                                        }
                                    }
                                }
                                .background(Color.cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .warmShadow()
                                .padding(.horizontal, 20)
                            }
                        }

                        if !past.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionLabel(title: "Past", dotColor: Color.mutedFg.opacity(0.4))
                                    .padding(.horizontal, 20)

                                VStack(spacing: 0) {
                                    ForEach(Array(past.enumerated()), id: \.element.id) { index, appt in
                                        Button { selected = appt } label: {
                                            AppointmentCardRow(appointment: appt)
                                        }
                                        .buttonStyle(.plain)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) { modelContext.delete(appt) } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        if index < past.count - 1 {
                                            Divider().padding(.leading, 82)
                                        }
                                    }
                                }
                                .background(Color.cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .warmShadow()
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color.bg)
        .sheet(isPresented: $showAdd) { AddAppointmentView() }
        .sheet(item: $selected) { appt in
            AppointmentDetailSheet(appointment: appt) {
                modelContext.delete(appt)
                selected = nil
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 28))
                .foregroundStyle(Color.cyanStart.opacity(0.4))
                .frame(width: 64, height: 64)
                .background(Color.cyanStart.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            Text("No appointments")
                .font(.system(size: 15))
                .foregroundStyle(Color.mutedFg)
            Text("Tap + to schedule one")
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

// MARK: - Appointment Detail Sheet

struct AppointmentDetailSheet: View {
    let appointment: Appointment
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.title)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.nearBlack)
                    if !appointment.doctorName.isEmpty {
                        Text(appointment.doctorName)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.primaryTeal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)

                VStack(spacing: 10) {
                    detailRow(icon: "calendar", iconColor: Color.cyanStart,
                              label: "Date",
                              value: appointment.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))

                    if !appointment.time.isEmpty {
                        detailRow(icon: "clock", iconColor: Color.primaryTeal,
                                  label: "Time", value: appointment.time)
                    }
                    if !appointment.location.isEmpty {
                        detailRow(icon: "mappin", iconColor: Color.amberStart,
                                  label: "Location", value: appointment.location)
                    }
                    if !appointment.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.mutedFg)
                            Text(appointment.notes)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.nearBlack)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color.bg)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                Button {
                    onDelete()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("Cancel Appointment")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "DC2626"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "DC2626").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color.cardBg)
            .navigationTitle("Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(24)
    }

    func detailRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mutedFg)
                Text(value)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.nearBlack)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.bg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Add Appointment Sheet

struct AddAppointmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Doctor.createdAt) private var doctors: [Doctor]

    @State private var title = ""
    @State private var doctorName = ""
    @State private var date = Date()
    @State private var time = ""
    @State private var location = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(LinearGradient(colors: [.cyanStart, .cyanEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Text("New Appointment")
                            .font(.headline)
                    }
                }

                Section("Appointment Info") {
                    TextField("Title (e.g. Annual Physical)", text: $title)
                    if doctors.isEmpty {
                        TextField("Doctor Name", text: $doctorName)
                    } else {
                        Picker("Doctor", selection: $doctorName) {
                            Text("None").tag("")
                            ForEach(doctors) { doc in
                                Text(doc.name).tag(doc.name)
                            }
                        }
                    }
                }

                Section("Date & Time") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Time (e.g. 10:00 AM)", text: $time)
                }

                Section("Details") {
                    TextField("Location", text: $location)
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationCornerRadius(24)
    }

    private func save() {
        modelContext.insert(Appointment(
            title: title.trimmingCharacters(in: .whitespaces),
            doctorName: doctorName.trimmingCharacters(in: .whitespaces),
            date: date,
            time: time.trimmingCharacters(in: .whitespaces),
            location: location.trimmingCharacters(in: .whitespaces),
            notes: notes.trimmingCharacters(in: .whitespaces)
        ))
        dismiss()
    }
}
