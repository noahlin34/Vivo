//
//  MedicationsView.swift
//  Vivo
//

import SwiftUI
import SwiftData
import UserNotifications

struct MedicationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medication.scheduledTime) private var medications: [Medication]
    @State private var showAdd = false
    @State private var selected: Medication? = nil
    @State private var searchText = ""
    @State private var medicationToDelete: Medication? = nil

    private var groupedMedications: [(TimeOfDay, [Medication])] {
        let base = searchText.isEmpty
            ? Array(medications)
            : medications.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        var groups: [TimeOfDay: [Medication]] = [:]
        for med in base {
            let tod = TimeOfDay.from(date: med.scheduledTime)
            groups[tod, default: []].append(med)
        }
        return TimeOfDay.allCases.compactMap { tod in
            guard let meds = groups[tod] else { return nil }
            let sorted = meds.sorted { lhs, rhs in
                if lhs.isTakenToday != rhs.isTakenToday { return !lhs.isTakenToday }
                return lhs.scheduledTime < rhs.scheduledTime
            }
            return (tod, sorted)
        }
    }

    private func toggleTaken(_ medication: Medication) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            if medication.frequency == "As needed" {
                medication.takenDates.append(Date())
                if let count = medication.pillCount, count > 0 {
                    medication.pillCount = count - 1
                }
            } else if medication.isTakenToday {
                let todayCount = medication.dosesTakenToday
                medication.takenDates = medication.takenDates.filter {
                    !Calendar.current.isDateInToday($0)
                }
                if let count = medication.pillCount {
                    medication.pillCount = count + todayCount
                }
            } else {
                medication.takenDates.append(Date())
                if let count = medication.pillCount, count > 0 {
                    medication.pillCount = count - 1
                }
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Medications")
                            .font(.system(size: 28, weight: .regular, design: .serif))
                            .foregroundStyle(Color.nearBlack)
                        Text("\(medications.count) medication\(medications.count == 1 ? "" : "s") tracked")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mutedFg)
                    }
                    Spacer()
                    GradientAddButton(gradient: [.tealStart, .tealEnd]) { showAdd = true }
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 20)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.mutedFg.opacity(0.6))
                    TextField("Search medications...", text: $searchText)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .warmShadow()
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                // Content
                if medications.isEmpty {
                    emptyState
                } else if groupedMedications.isEmpty {
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
                    VStack(spacing: 24) {
                        ForEach(groupedMedications, id: \.0.rawValue) { tod, meds in
                            VStack(alignment: .leading, spacing: 10) {
                                // Time-of-day section header
                                HStack(spacing: 7) {
                                    Image(systemName: tod.icon)
                                        .font(.system(size: 11))
                                        .foregroundStyle(tod.color)
                                    Text(tod.rawValue.uppercased())
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color.mutedFg)
                                        .tracking(0.5)
                                    Spacer()
                                    let remaining = meds.filter { !$0.isTakenToday && $0.dosesRequired > 0 }.count
                                    if remaining > 0 {
                                        Text("\(remaining) remaining")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.mutedFg.opacity(0.55))
                                    }
                                }

                                VStack(spacing: 10) {
                                    ForEach(meds) { med in
                                        Button { selected = med } label: {
                                            MedicationCardRow(medication: med, onToggle: { toggleTaken(med) })
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: meds.map(\.isTakenToday))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 100)
            }
        }
        .background(Color.bg)
        .confirmationDialog(
            "Remove \(medicationToDelete?.name ?? "Medication")?",
            isPresented: Binding(get: { medicationToDelete != nil }, set: { if !$0 { medicationToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let med = medicationToDelete {
                    MedicationNotifications.cancel(for: med)
                    modelContext.delete(med)
                    medicationToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { medicationToDelete = nil }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $showAdd) { AddMedicationView() }
        .sheet(item: $selected) { med in
            MedicationDetailSheet(medication: med) {
                MedicationNotifications.cancel(for: med)
                modelContext.delete(med)
                selected = nil
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "pill.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.primaryTeal.opacity(0.4))
                .frame(width: 64, height: 64)
                .background(Color.primaryTeal.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            Text("No medications added")
                .font(.system(size: 15))
                .foregroundStyle(Color.mutedFg)
            Text("Tap + to add your first medication")
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

// MARK: - Medication Detail Sheet

struct MedicationDetailSheet: View {
    let medication: Medication
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationStatusMonitor.self) private var notificationStatus
    @State private var showEdit = false
    @State private var showRefill = false
    @State private var refillAmount = 30

    private var color: Color { .medColor(medication.colorIndex) }

    private var reminderText: String {
        guard medication.frequency != "As needed" else { return "No reminders" }
        guard medication.reminderOffset != -1 else { return "No reminders" }

        let base = medication.scheduledTime
        let cal = Calendar.current
        let minuteOffset = medication.reminderOffset

        func fireTimeString(addingHours hourOffset: Int) -> String {
            let doseDate = cal.date(byAdding: .hour, value: hourOffset, to: base) ?? base
            let fireDate = cal.date(byAdding: .minute, value: -minuteOffset, to: doseDate) ?? doseDate
            return fireDate.formatted(.dateTime.hour().minute())
        }

        switch medication.frequency {
        case "Once daily":
            return "Daily at \(fireTimeString(addingHours: 0))"
        case "Twice daily":
            return "Daily at \(fireTimeString(addingHours: 0)), \(fireTimeString(addingHours: 12))"
        case "Three times daily":
            return "Daily at \(fireTimeString(addingHours: 0)), \(fireTimeString(addingHours: 8)), \(fireTimeString(addingHours: 16))"
        default:
            return "No reminders"
        }
    }

    private var last7Days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
    }

    private func dosesOn(_ day: Date) -> Int {
        let cal = Calendar.current
        return medication.takenDates.filter { cal.isDate($0, inSameDayAs: day) }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DetailToolbar(title: "Medication Details",
                              onDone: { dismiss() },
                              onEdit: { showEdit = true })
                ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 16) {
                        Image(systemName: "pill.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(color)
                            .frame(width: 64, height: 64)
                            .background(color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(medication.name)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(Color.nearBlack)
                            Text(medication.dosage)
                                .font(.system(size: 12))
                                .foregroundStyle(color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(color.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)

                    // Details
                    VStack(spacing: 0) {
                        detailRow(label: "Frequency", value: medication.frequency)
                        Divider().padding(.leading, 16)
                        detailRow(label: "Time", value: medication.scheduledTime.formatted(.dateTime.hour().minute()))
                        if medication.frequency != "As needed" {
                            Divider().padding(.leading, 16)
                            reminderRow
                        }
                        if !medication.notes.isEmpty {
                            Divider().padding(.leading, 16)
                            detailRow(label: "Notes", value: medication.notes)
                        }
                        if let count = medication.pillCount {
                            Divider().padding(.leading, 16)
                            let supplyText: String = {
                                if count == 0 { return "Refill needed" }
                                if let days = medication.daysRemaining { return "\(count) pills · ~\(days)d" }
                                return "\(count) pills"
                            }()
                            HStack {
                                Text("Supply")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.mutedFg)
                                Spacer()
                                HStack(spacing: 5) {
                                    if medication.isLowSupply {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.amberStart)
                                    }
                                    Text(supplyText)
                                        .font(.system(size: 14))
                                        .foregroundStyle(medication.isLowSupply ? Color.amberStart : Color.nearBlack)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            Divider().padding(.leading, 16)
                            Button {
                                showRefill = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 13))
                                    Text("Log Refill")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundStyle(color)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                        }
                    }
                    .background(Color.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)

                    // 7-day adherence
                    if medication.frequency != "As needed" {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Last 7 Days")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.nearBlack)
                                Spacer()
                                let takenDays = last7Days.filter { dosesOn($0) >= medication.dosesRequired }.count
                                Text("\(takenDays)/7 days")
                                    .font(.system(size: 12))
                                    .foregroundStyle(color)
                            }

                            HStack(spacing: 0) {
                                ForEach(last7Days, id: \.self) { day in
                                    let doses = dosesOn(day)
                                    let complete = doses >= medication.dosesRequired
                                    let isToday = Calendar.current.isDateInToday(day)

                                    VStack(spacing: 5) {
                                        Text(day.formatted(.dateTime.weekday(.narrow)))
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(Color.mutedFg)
                                        ZStack {
                                            Circle()
                                                .fill(complete ? color : Color.mutedBg)
                                                .frame(width: 30, height: 30)
                                            if complete {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundStyle(.white)
                                            } else if doses > 0 {
                                                Text("\(doses)")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundStyle(color)
                                            }
                                        }
                                        if isToday {
                                            Circle()
                                                .fill(color)
                                                .frame(width: 4, height: 4)
                                        } else {
                                            Spacer().frame(height: 4)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.bg)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }

                    // Delete button
                    Button {
                        onDelete()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("Remove Medication")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.destructive)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.destructive.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
            }
            }
            .background(Color.cardBg)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showEdit) {
                EditMedicationView(medication: medication)
            }
            .alert("Log Refill", isPresented: $showRefill) {
                TextField("Number of pills", value: $refillAmount, format: .number)
                    .keyboardType(.numberPad)
                Button("Add") {
                    medication.pillCount = (medication.pillCount ?? 0) + refillAmount
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("How many pills are you adding?")
            }
            }
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(24)
    }

    var reminderRow: some View {
        HStack {
            Text("Reminders")
                .font(.system(size: 12))
                .foregroundStyle(Color.mutedFg)
            Spacer()
            HStack(spacing: 5) {
                Text(reminderText)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.nearBlack)
                    .multilineTextAlignment(.trailing)
                if notificationStatus.isDenied && medication.reminderOffset != -1 {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.amberStart)
                    Text("(off)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.amberStart)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.mutedFg)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(Color.nearBlack)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Add Medication Sheet

struct AddMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = "Once daily"
    @State private var scheduledTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var notes = ""
    @State private var colorIndex = 0
    @State private var reminderOffset: Int = 0
    @State private var trackPillCount = false
    @State private var pillCount = 30

    private let frequencies = ["Once daily", "Twice daily", "Three times daily", "As needed"]
    private let colorNames = ["Teal", "Green", "Amber", "Purple", "Cyan", "Rose"]
    private let colorHexes = Color.medHexColors

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FormToolbar(title: "Add Medication", gradient: [Color.tealStart, Color.tealEnd],
                            saveDisabled: name.trimmingCharacters(in: .whitespaces).isEmpty,
                            onCancel: { dismiss() }, onSave: { save() })
                ScrollView {
                    VStack(spacing: 20) {
                        FormHeader(
                            icon: "pill.fill",
                            title: "Add Medication",
                            subtitle: "Track your daily prescriptions",
                            gradient: [.tealStart, .tealEnd]
                        )
                        FormSection(title: "Info") {
                            FormTextField(label: "Name", text: $name, placeholder: "Medication name", icon: "pill.fill")
                            FormTextField(label: "Dosage", text: $dosage, placeholder: "e.g. 10mg", icon: "scalemass.fill")
                            FormTextField(label: "Notes", text: $notes, placeholder: "Optional", icon: "note.text")
                        }
                        FormSection(title: "Schedule") {
                            FormChipPicker(
                                selection: $frequency,
                                options: frequencies,
                                labels: { $0 },
                                gradient: [.tealStart, .tealEnd]
                            )
                            HStack(spacing: 10) {
                                Image(systemName: "clock")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.primaryTeal)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Time")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.mutedFg)
                                    DatePicker("", selection: $scheduledTime, displayedComponents: .hourAndMinute)
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
                            if frequency != "As needed" {
                                HStack(spacing: 10) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.primaryTeal)
                                        .frame(width: 20)
                                    Text("Reminder")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.mutedFg)
                                    Spacer()
                                    Menu {
                                        ForEach(MedicationReminderOffset.allCases, id: \.rawValue) { option in
                                            Button(option.label) { reminderOffset = option.rawValue }
                                        }
                                    } label: {
                                        Text(MedicationReminderOffset(rawValue: reminderOffset)?.label ?? "At dose time")
                                            .font(.system(size: 14))
                                    }
                                    .tint(Color.nearBlack)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.mutedBg.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        FormSection(title: "Color") {
                            FormColorPicker(selection: $colorIndex, colors: colorHexes, names: colorNames)
                        }
                        FormSection(title: "Refill Tracking") {
                            Toggle(isOn: $trackPillCount) {
                                Text("Track pill supply")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.nearBlack)
                            }
                            .tint(Color.primaryTeal)
                            if trackPillCount {
                                HStack {
                                    Text("Initial supply")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.nearBlack)
                                    Spacer()
                                    Stepper("\(pillCount) pill\(pillCount == 1 ? "" : "s")", value: $pillCount, in: 0...999)
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.nearBlack)
                                }
                            }
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

    private func save() {
        let med = Medication(
            name: name.trimmingCharacters(in: .whitespaces),
            dosage: dosage.trimmingCharacters(in: .whitespaces),
            frequency: frequency,
            scheduledTime: scheduledTime,
            colorIndex: colorIndex,
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        med.pillCount = trackPillCount ? pillCount : nil
        med.reminderOffset = reminderOffset
        modelContext.insert(med)
        MedicationNotifications.schedule(for: med)
        dismiss()
    }
}

// MARK: - Edit Medication Sheet

struct EditMedicationView: View {
    let medication: Medication
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var dosage: String
    @State private var frequency: String
    @State private var scheduledTime: Date
    @State private var colorIndex: Int
    @State private var notes: String
    @State private var reminderOffset: Int
    @State private var trackPillCount: Bool
    @State private var pillCount: Int

    private let frequencies = ["Once daily", "Twice daily", "Three times daily", "As needed"]
    private let colorNames = ["Teal", "Green", "Amber", "Purple", "Cyan", "Rose"]
    private let colorHexes = Color.medHexColors

    init(medication: Medication) {
        self.medication = medication
        _name = State(initialValue: medication.name)
        _dosage = State(initialValue: medication.dosage)
        _frequency = State(initialValue: medication.frequency)
        _scheduledTime = State(initialValue: medication.scheduledTime)
        _colorIndex = State(initialValue: medication.colorIndex)
        _notes = State(initialValue: medication.notes)
        _reminderOffset = State(initialValue: medication.reminderOffset)
        _trackPillCount = State(initialValue: medication.pillCount != nil)
        _pillCount = State(initialValue: medication.pillCount ?? 30)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FormToolbar(title: "Edit Medication", gradient: [Color.tealStart, Color.tealEnd],
                            saveDisabled: name.trimmingCharacters(in: .whitespaces).isEmpty,
                            onCancel: { dismiss() }, onSave: { save() })
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Info") {
                            FormTextField(label: "Name", text: $name, placeholder: "Medication name", icon: "pill.fill")
                            FormTextField(label: "Dosage", text: $dosage, placeholder: "e.g. 10mg", icon: "scalemass.fill")
                            FormTextField(label: "Notes", text: $notes, placeholder: "Optional", icon: "note.text")
                        }
                        FormSection(title: "Schedule") {
                            FormChipPicker(
                                selection: $frequency,
                                options: frequencies,
                                labels: { $0 },
                                gradient: [.tealStart, .tealEnd]
                            )
                            HStack(spacing: 10) {
                                Image(systemName: "clock")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.primaryTeal)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Time")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.mutedFg)
                                    DatePicker("", selection: $scheduledTime, displayedComponents: .hourAndMinute)
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
                            if frequency != "As needed" {
                                HStack(spacing: 10) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.primaryTeal)
                                        .frame(width: 20)
                                    Text("Reminder")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.mutedFg)
                                    Spacer()
                                    Menu {
                                        ForEach(MedicationReminderOffset.allCases, id: \.rawValue) { option in
                                            Button(option.label) { reminderOffset = option.rawValue }
                                        }
                                    } label: {
                                        Text(MedicationReminderOffset(rawValue: reminderOffset)?.label ?? "At dose time")
                                            .font(.system(size: 14))
                                    }
                                    .tint(Color.nearBlack)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.mutedBg.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        FormSection(title: "Color") {
                            FormColorPicker(selection: $colorIndex, colors: colorHexes, names: colorNames)
                        }
                        FormSection(title: "Refill Tracking") {
                            Toggle(isOn: $trackPillCount) {
                                Text("Track pill supply")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.nearBlack)
                            }
                            .tint(Color.primaryTeal)
                            if trackPillCount {
                                HStack {
                                    Text("Current supply")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.nearBlack)
                                    Spacer()
                                    Stepper("\(pillCount) pill\(pillCount == 1 ? "" : "s")", value: $pillCount, in: 0...999)
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.nearBlack)
                                }
                            }
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

    private func save() {
        medication.name = name.trimmingCharacters(in: .whitespaces)
        medication.dosage = dosage.trimmingCharacters(in: .whitespaces)
        medication.frequency = frequency
        medication.scheduledTime = scheduledTime
        medication.colorIndex = colorIndex
        medication.notes = notes.trimmingCharacters(in: .whitespaces)
        medication.reminderOffset = reminderOffset
        medication.pillCount = trackPillCount ? pillCount : nil
        MedicationNotifications.schedule(for: medication)
        dismiss()
    }
}

// MARK: - Medication Reminder Offset

enum MedicationReminderOffset: Int, CaseIterable {
    case none        = -1
    case atDoseTime  = 0
    case fiveMin     = 5
    case fifteenMin  = 15
    case thirtyMin   = 30
    case oneHour     = 60

    var label: String {
        switch self {
        case .none:       return "None"
        case .atDoseTime: return "At dose time"
        case .fiveMin:    return "5 min before"
        case .fifteenMin: return "15 min before"
        case .thirtyMin:  return "30 min before"
        case .oneHour:    return "1 hour before"
        }
    }
}

// MARK: - Time of Day

enum TimeOfDay: String, CaseIterable {
    case morning   = "Morning"
    case afternoon = "Afternoon"
    case evening   = "Evening"
    case night     = "Night"

    static func from(date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default:     return .night
        }
    }

    var icon: String {
        switch self {
        case .morning:   return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening:   return "sunset.fill"
        case .night:     return "moon.stars.fill"
        }
    }

    var color: Color {
        switch self {
        case .morning:   return Color.amberStart
        case .afternoon: return Color.cyanStart
        case .evening:   return Color.purpleStart
        case .night:     return Color(hex: "6366F1")
        }
    }
}

// MARK: - Notification Manager

enum MedicationNotifications {
    private static func baseId(for medication: Medication) -> String {
        String(medication.createdAt.timeIntervalSince1970)
    }

    static func schedule(for medication: Medication) {
        let center = UNUserNotificationCenter.current()
        let base = baseId(for: medication)

        center.removePendingNotificationRequests(withIdentifiers: ["\(base)-0", "\(base)-1", "\(base)-2"])
        guard medication.frequency != "As needed" else { return }
        guard medication.reminderOffset != -1 else { return }

        let hourOffsets: [Int]
        switch medication.frequency {
        case "Twice daily":       hourOffsets = [0, 12]
        case "Three times daily": hourOffsets = [0, 8, 16]
        default:                  hourOffsets = [0]
        }

        let name = medication.name
        let dosage = medication.dosage
        let scheduledTime = medication.scheduledTime
        let minuteOffset = medication.reminderOffset

        NotificationService.ensureAuthorizedThenSchedule { center in
            for (i, hourOffset) in hourOffsets.enumerated() {
                let doseDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: scheduledTime) ?? scheduledTime
                let fireDate = Calendar.current.date(byAdding: .minute, value: -minuteOffset, to: doseDate) ?? doseDate
                let components = Calendar.current.dateComponents([.hour, .minute], from: fireDate)

                let content = UNMutableNotificationContent()
                if minuteOffset == 60 {
                    content.title = "Take \(name) in 1 hour"
                } else if minuteOffset > 0 {
                    content.title = "Take \(name) in \(minuteOffset) min"
                } else {
                    content.title = "Time to take \(name)"
                }
                content.body = dosage
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: "\(base)-\(i)", content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    static func cancel(for medication: Medication) {
        let base = baseId(for: medication)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["\(base)-0", "\(base)-1", "\(base)-2"]
        )
    }
}
