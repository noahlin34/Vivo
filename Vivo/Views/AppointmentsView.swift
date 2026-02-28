//
//  AppointmentsView.swift
//  Vivo
//

import SwiftUI
import SwiftData
import UserNotifications

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
                .padding(.top, 56)
                .padding(.bottom, 20)

                if appointments.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 20) {
                        if !upcoming.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionLabel(title: "Upcoming", dotColor: Color.primaryTeal)
                                    .padding(.horizontal, 20)

                                VStack(spacing: 10) {
                                    ForEach(upcoming) { appt in
                                        Button { selected = appt } label: {
                                            AppointmentCardRow(appointment: appt, showTodayBadge: true)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        if !past.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionLabel(title: "Past", dotColor: Color.mutedFg.opacity(0.4))
                                    .padding(.horizontal, 20)

                                VStack(spacing: 10) {
                                    ForEach(past) { appt in
                                        Button { selected = appt } label: {
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
        .background(Color.bg)
        .sheet(isPresented: $showAdd) { AddAppointmentView() }
        .sheet(item: $selected) { appt in
            AppointmentDetailSheet(appointment: appt) {
                AppointmentNotifications.cancel(for: appt)
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
    @State private var showEdit = false
    @State private var showLinkedDoctor = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.title)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.nearBlack)
                    if let linkedDoctor = appointment.doctor {
                        Button { showLinkedDoctor = true } label: {
                            HStack(spacing: 4) {
                                Text(linkedDoctor.name)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.primaryTeal)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.primaryTeal.opacity(0.5))
                            }
                        }
                        .buttonStyle(.plain)
                    } else if !appointment.doctorName.isEmpty {
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

                    detailRow(icon: "clock", iconColor: Color.primaryTeal,
                              label: "Time", value: appointment.date.formatted(.dateTime.hour().minute()))
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
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showEdit = true }
                }
            }
            .sheet(isPresented: $showEdit) {
                EditAppointmentView(appointment: appointment)
            }
            .sheet(isPresented: $showLinkedDoctor) {
                if let doc = appointment.doctor {
                    DoctorDetailSheet(doctor: doc) { }
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
    @State private var selectedDoctor: Doctor? = nil
    @State private var doctorName = ""
    @State private var date = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
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
                        Picker("Doctor", selection: $selectedDoctor) {
                            Text("None").tag(nil as Doctor?)
                            ForEach(doctors) { doc in
                                Text(doc.name).tag(doc as Doctor?)
                            }
                        }
                    }
                }

                Section("Date & Time") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Time", selection: $date, displayedComponents: .hourAndMinute)
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
        let appt = Appointment(
            title: title.trimmingCharacters(in: .whitespaces),
            doctorName: selectedDoctor?.name ?? doctorName.trimmingCharacters(in: .whitespaces),
            date: date,
            location: location.trimmingCharacters(in: .whitespaces),
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        appt.doctor = selectedDoctor
        modelContext.insert(appt)
        AppointmentNotifications.schedule(for: appt)
        dismiss()
    }
}

// MARK: - Edit Appointment Sheet

struct EditAppointmentView: View {
    let appointment: Appointment
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Doctor.createdAt) private var doctors: [Doctor]

    @State private var title: String
    @State private var selectedDoctor: Doctor?
    @State private var doctorName: String
    @State private var date: Date
    @State private var location: String
    @State private var notes: String

    init(appointment: Appointment) {
        self.appointment = appointment
        _title = State(initialValue: appointment.title)
        _selectedDoctor = State(initialValue: appointment.doctor)
        _doctorName = State(initialValue: appointment.doctorName)
        _date = State(initialValue: appointment.date)
        _location = State(initialValue: appointment.location)
        _notes = State(initialValue: appointment.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Appointment Info") {
                    TextField("Title", text: $title)
                    if doctors.isEmpty {
                        TextField("Doctor Name", text: $doctorName)
                    } else {
                        Picker("Doctor", selection: $selectedDoctor) {
                            Text("None").tag(nil as Doctor?)
                            ForEach(doctors) { doc in
                                Text(doc.name).tag(doc as Doctor?)
                            }
                        }
                    }
                }
                Section("Date & Time") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Time", selection: $date, displayedComponents: .hourAndMinute)
                }
                Section("Details") {
                    TextField("Location", text: $location)
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle("Edit Appointment")
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
        appointment.title = title.trimmingCharacters(in: .whitespaces)
        appointment.doctorName = selectedDoctor?.name ?? doctorName.trimmingCharacters(in: .whitespaces)
        appointment.doctor = selectedDoctor
        appointment.date = date
        appointment.location = location.trimmingCharacters(in: .whitespaces)
        appointment.notes = notes.trimmingCharacters(in: .whitespaces)
        AppointmentNotifications.schedule(for: appointment)
        dismiss()
    }
}

// MARK: - Appointment Notifications

enum AppointmentNotifications {
    private static func baseId(for appointment: Appointment) -> String {
        String(appointment.createdAt.timeIntervalSince1970)
    }

    static func schedule(for appointment: Appointment) {
        let center = UNUserNotificationCenter.current()
        let base = baseId(for: appointment)

        // Cancel any existing notifications before rescheduling (handles edits)
        center.removePendingNotificationRequests(withIdentifiers: ["\(base)-day", "\(base)-hour"])

        let now = Date()
        let doctorPart = appointment.displayDoctorName.isEmpty ? "" : " with \(appointment.displayDoctorName)"

        // 1 day before
        if let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: appointment.date),
           dayBefore > now {
            let content = UNMutableNotificationContent()
            content.title = "Appointment tomorrow"
            content.body = "\(appointment.title)\(doctorPart)"
            content.sound = .default
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dayBefore)
            center.add(UNNotificationRequest(
                identifier: "\(base)-day",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            ))
        }

        // 1 hour before
        if let hourBefore = Calendar.current.date(byAdding: .hour, value: -1, to: appointment.date),
           hourBefore > now {
            let content = UNMutableNotificationContent()
            content.title = "Appointment in 1 hour"
            content.body = "\(appointment.title)\(doctorPart)"
            content.sound = .default
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: hourBefore)
            center.add(UNNotificationRequest(
                identifier: "\(base)-hour",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            ))
        }
    }

    static func cancel(for appointment: Appointment) {
        let base = baseId(for: appointment)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["\(base)-day", "\(base)-hour"]
        )
    }
}
