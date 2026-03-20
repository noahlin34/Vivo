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
    @State private var searchText = ""

    private var filtered: [Appointment] {
        guard !searchText.isEmpty else { return appointments }
        return appointments.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.displayDoctorName.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
    }
    private var upcoming: [Appointment] {
        filtered.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }
    }
    private var past: [Appointment] {
        filtered.filter { $0.date < Calendar.current.startOfDay(for: Date()) }.reversed()
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

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.mutedFg.opacity(0.6))
                    TextField("Search appointments...", text: $searchText)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .warmShadow()
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                if appointments.isEmpty {
                    emptyState
                } else if filtered.isEmpty {
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
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationStatusMonitor.self) private var notificationStatus
    @State private var showEdit = false
    @State private var showLinkedDoctor = false

    private var reminderValue: String {
        let now = Date()
        let apptDate = appointment.date
        guard apptDate > now else { return "No reminders (past)" }
        let option = AppointmentReminderOption(rawValue: appointment.reminderOption) ?? .oneDayOneHour
        if option == .none { return "No reminders" }
        return option.label
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DetailToolbar(title: "Appointment", onDone: { dismiss() }, onEdit: { showEdit = true })
                ScrollView {
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
                        reminderRow
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }

                Button {
                    onDelete()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("Cancel Appointment")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.destructive)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.destructive.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color.cardBg)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showEdit) {
                EditAppointmentView(appointment: appointment)
            }
            .sheet(isPresented: $showLinkedDoctor) {
                if let doc = appointment.doctor {
                    DoctorDetailSheet(doctor: doc) {
                        modelContext.delete(doc)
                        showLinkedDoctor = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(24)
    }

    var reminderRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.system(size: 15))
                .foregroundStyle(Color.primaryTeal)
                .frame(width: 36, height: 36)
                .background(Color.primaryTeal.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Reminders")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mutedFg)
                HStack(spacing: 5) {
                    Text(reminderValue)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.nearBlack)
                    let intentionallyOff = appointment.reminderOption == "none"
                    if notificationStatus.isDenied && reminderValue != "No reminders (past)" && !intentionallyOff {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.amberStart)
                        Text("(off)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.amberStart)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.bg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
    @State private var reminderOption = "1_day_1_hour"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FormToolbar(title: "New Appointment", gradient: [Color.amberStart, Color.amberEnd],
                            saveDisabled: title.trimmingCharacters(in: .whitespaces).isEmpty,
                            onCancel: { dismiss() }, onSave: { save() })
                ScrollView {
                    VStack(spacing: 20) {
                        FormHeader(
                            icon: "calendar",
                            title: "New Appointment",
                            subtitle: "Schedule your next visit",
                            gradient: [.amberStart, .amberEnd]
                        )
                        FormSection(title: "Info", dotColor: Color.amberStart) {
                            FormTextField(label: "Title", text: $title, placeholder: "e.g. Annual Physical", icon: "calendar")
                            doctorRow
                        }
                        FormSection(title: "Date & Time", dotColor: Color.amberStart) {
                            datePickerRow(label: "Date", icon: "calendar", components: .date)
                            datePickerRow(label: "Time", icon: "clock", components: .hourAndMinute)
                        }
                        FormSection(title: "Reminders", dotColor: Color.amberStart) {
                            HStack(spacing: 10) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.primaryTeal)
                                    .frame(width: 20)
                                Text("Remind me")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.mutedFg)
                                Spacer()
                                Picker("", selection: $reminderOption) {
                                    ForEach(AppointmentReminderOption.allCases, id: \.rawValue) { option in
                                        Text(option.label).tag(option.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color.nearBlack)
                                .font(.system(size: 14))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.mutedBg.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        FormSection(title: "Details", dotColor: Color.amberStart) {
                            FormTextField(label: "Location", text: $location, placeholder: "Optional", icon: "mappin.circle.fill")
                            FormTextField(label: "Notes", text: $notes, placeholder: "Optional", icon: "note.text")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .background(Color.bg)
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationCornerRadius(24)
    }

    @ViewBuilder
    private var doctorRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.primaryTeal)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text("Doctor")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mutedFg)
                if doctors.isEmpty {
                    TextField("Doctor name (optional)", text: $doctorName)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.nearBlack)
                } else {
                    Menu {
                        Button("None") { selectedDoctor = nil }
                        ForEach(doctors) { doc in
                            Button(doc.name) { selectedDoctor = doc }
                        }
                    } label: {
                        HStack {
                            Text(selectedDoctor?.name ?? "Select doctor")
                                .font(.system(size: 15))
                                .foregroundStyle(selectedDoctor == nil ? Color.mutedFg : Color.nearBlack)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.mutedFg.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.mutedBg.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func datePickerRow(label: String, icon: String, components: DatePickerComponents) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.primaryTeal)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mutedFg)
                DatePicker("", selection: $date, displayedComponents: components)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Color.primaryTeal)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.mutedBg.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
        appt.reminderOption = reminderOption
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
    @State private var reminderOption: String

    init(appointment: Appointment) {
        self.appointment = appointment
        _title = State(initialValue: appointment.title)
        _selectedDoctor = State(initialValue: appointment.doctor)
        _doctorName = State(initialValue: appointment.doctorName)
        _date = State(initialValue: appointment.date)
        _location = State(initialValue: appointment.location)
        _notes = State(initialValue: appointment.notes)
        _reminderOption = State(initialValue: appointment.reminderOption)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FormToolbar(title: "Edit Appointment", gradient: [Color.amberStart, Color.amberEnd],
                            saveDisabled: title.trimmingCharacters(in: .whitespaces).isEmpty,
                            onCancel: { dismiss() }, onSave: { save() })
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Info", dotColor: Color.amberStart) {
                            FormTextField(label: "Title", text: $title, placeholder: "e.g. Annual Physical", icon: "calendar")
                            doctorRow
                        }
                        FormSection(title: "Date & Time", dotColor: Color.amberStart) {
                            datePickerRow(label: "Date", icon: "calendar", components: .date)
                            datePickerRow(label: "Time", icon: "clock", components: .hourAndMinute)
                        }
                        FormSection(title: "Reminders", dotColor: Color.amberStart) {
                            HStack(spacing: 10) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.primaryTeal)
                                    .frame(width: 20)
                                Text("Remind me")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.mutedFg)
                                Spacer()
                                Picker("", selection: $reminderOption) {
                                    ForEach(AppointmentReminderOption.allCases, id: \.rawValue) { option in
                                        Text(option.label).tag(option.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color.nearBlack)
                                .font(.system(size: 14))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.mutedBg.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        FormSection(title: "Details", dotColor: Color.amberStart) {
                            FormTextField(label: "Location", text: $location, placeholder: "Optional", icon: "mappin.circle.fill")
                            FormTextField(label: "Notes", text: $notes, placeholder: "Optional", icon: "note.text")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .background(Color.bg)
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationCornerRadius(24)
    }

    @ViewBuilder
    private var doctorRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.primaryTeal)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text("Doctor")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mutedFg)
                if doctors.isEmpty {
                    TextField("Doctor name (optional)", text: $doctorName)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.nearBlack)
                } else {
                    Menu {
                        Button("None") { selectedDoctor = nil }
                        ForEach(doctors) { doc in
                            Button(doc.name) { selectedDoctor = doc }
                        }
                    } label: {
                        HStack {
                            Text(selectedDoctor?.name ?? "Select doctor")
                                .font(.system(size: 15))
                                .foregroundStyle(selectedDoctor == nil ? Color.mutedFg : Color.nearBlack)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.mutedFg.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.mutedBg.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func datePickerRow(label: String, icon: String, components: DatePickerComponents) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.primaryTeal)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mutedFg)
                DatePicker("", selection: $date, displayedComponents: components)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Color.primaryTeal)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.mutedBg.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func save() {
        appointment.title = title.trimmingCharacters(in: .whitespaces)
        appointment.doctorName = selectedDoctor?.name ?? doctorName.trimmingCharacters(in: .whitespaces)
        appointment.doctor = selectedDoctor
        appointment.date = date
        appointment.location = location.trimmingCharacters(in: .whitespaces)
        appointment.notes = notes.trimmingCharacters(in: .whitespaces)
        appointment.reminderOption = reminderOption
        AppointmentNotifications.schedule(for: appointment)
        dismiss()
    }
}

// MARK: - Appointment Reminder Option

enum AppointmentReminderOption: String, CaseIterable {
    case none         = "none"
    case atTime       = "at_time"
    case fiveMin      = "5_min"
    case fifteenMin   = "15_min"
    case thirtyMin    = "30_min"
    case oneHour      = "1_hour"
    case twoHours     = "2_hours"
    case oneDay       = "1_day"
    case oneDayOneHour = "1_day_1_hour"

    var label: String {
        switch self {
        case .none:          return "None"
        case .atTime:        return "At time of event"
        case .fiveMin:       return "5 min before"
        case .fifteenMin:    return "15 min before"
        case .thirtyMin:     return "30 min before"
        case .oneHour:       return "1 hour before"
        case .twoHours:      return "2 hours before"
        case .oneDay:        return "1 day before"
        case .oneDayOneHour: return "1 day & 1 hour before"
        }
    }

    /// Time intervals (in seconds) before the appointment to fire each notification
    var offsets: [TimeInterval] {
        switch self {
        case .none:          return []
        case .atTime:        return [0]
        case .fiveMin:       return [300]
        case .fifteenMin:    return [900]
        case .thirtyMin:     return [1800]
        case .oneHour:       return [3600]
        case .twoHours:      return [7200]
        case .oneDay:        return [86400]
        case .oneDayOneHour: return [86400, 3600]
        }
    }

    func notificationTitle(for offset: TimeInterval) -> String {
        switch offset {
        case 0:     return "Appointment now"
        case 300:   return "Appointment in 5 minutes"
        case 900:   return "Appointment in 15 minutes"
        case 1800:  return "Appointment in 30 minutes"
        case 3600:  return "Appointment in 1 hour"
        case 7200:  return "Appointment in 2 hours"
        case 86400: return "Appointment tomorrow"
        default:    return "Upcoming appointment"
        }
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

        // Cancel both legacy and new identifiers for migration safety
        center.removePendingNotificationRequests(
            withIdentifiers: ["\(base)-day", "\(base)-hour", "\(base)-0", "\(base)-1"]
        )

        let option = AppointmentReminderOption(rawValue: appointment.reminderOption) ?? .oneDayOneHour
        guard !option.offsets.isEmpty else { return }

        let now = Date()
        let title = appointment.title
        let doctorPart = appointment.displayDoctorName.isEmpty ? "" : " with \(appointment.displayDoctorName)"
        let date = appointment.date

        NotificationService.ensureAuthorizedThenSchedule { center in
            for (i, offset) in option.offsets.enumerated() {
                guard let fireDate = Calendar.current.date(byAdding: .second, value: -Int(offset), to: date),
                      fireDate > now else { continue }
                let content = UNMutableNotificationContent()
                content.title = option.notificationTitle(for: offset)
                content.body = "\(title)\(doctorPart)"
                content.sound = .default
                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                center.add(UNNotificationRequest(
                    identifier: "\(base)-\(i)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                ))
            }
        }
    }

    static func cancel(for appointment: Appointment) {
        let base = baseId(for: appointment)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["\(base)-day", "\(base)-hour", "\(base)-0", "\(base)-1"]
        )
    }
}
