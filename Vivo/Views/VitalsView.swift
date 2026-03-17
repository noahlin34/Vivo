//
//  VitalsView.swift
//  Vivo
//

import SwiftUI
import SwiftData
import Charts

struct VitalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VitalRecord.recordedAt, order: .reverse) private var vitals: [VitalRecord]
    @State private var showAdd = false
    @State private var selected: VitalRecord? = nil
    @State private var searchText = ""
    @State private var selectedType: String? = nil
    @State private var healthKitService = HealthKitService()
    @State private var isImporting = false
    @State private var importResult: ImportResult? = nil

    private enum ImportResult: Identifiable {
        case success(Int)
        case error(String)

        var id: String {
            switch self {
            case .success(let n): return "success-\(n)"
            case .error(let msg): return "error-\(msg)"
            }
        }
    }

    private var subtitleText: String {
        let total = vitals.count
        let hkCount = vitals.filter { $0.source == "healthkit" }.count
        if hkCount > 0 {
            return "\(total) reading\(total == 1 ? "" : "s") (\(hkCount) from Apple Health)"
        }
        return "\(total) reading\(total == 1 ? "" : "s") logged"
    }

    private var filteredVitals: [VitalRecord] {
        var result = vitals
        if let type = selectedType {
            result = result.filter { $0.type == type }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.type.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    private var groupedVitals: [(String, [VitalRecord])] {
        let cal = Calendar.current
        var groups: [String: [VitalRecord]] = [:]
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        for vital in filteredVitals {
            let key: String
            if cal.isDateInToday(vital.recordedAt) {
                key = "Today"
            } else if cal.isDateInYesterday(vital.recordedAt) {
                key = "Yesterday"
            } else {
                key = formatter.string(from: vital.recordedAt)
            }
            groups[key, default: []].append(vital)
        }

        // Sort groups: Today first, then Yesterday, then by date descending
        return groups.sorted { lhs, rhs in
            if lhs.key == "Today" { return true }
            if rhs.key == "Today" { return false }
            if lhs.key == "Yesterday" { return true }
            if rhs.key == "Yesterday" { return false }
            return lhs.value.first?.recordedAt ?? .distantPast > rhs.value.first?.recordedAt ?? .distantPast
        }
    }

    private let typeFilters = VitalType.allCases

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vitals")
                            .font(.system(size: 28, weight: .regular, design: .serif))
                            .foregroundStyle(Color.nearBlack)
                        Text(subtitleText)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mutedFg)
                    }
                    Spacer()
                    if healthKitService.isAvailable {
                        Button {
                            Task { await importFromHealthKit() }
                        } label: {
                            Group {
                                if isImporting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                LinearGradient(colors: [.roseStart, .roseEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(isImporting)
                    }
                    GradientAddButton(gradient: [.roseStart, .roseEnd]) { showAdd = true }
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 20)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.mutedFg.opacity(0.6))
                    TextField("Search vitals...", text: $searchText)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .warmShadow()
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                // Type filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChip(title: "All", gradient: [.roseStart, .roseEnd], isSelected: selectedType == nil) {
                            selectedType = nil
                        }
                        ForEach(typeFilters, id: \.rawValue) { type in
                            CategoryChip(
                                title: type.rawValue,
                                gradient: type.gradient,
                                isSelected: selectedType == type.rawValue
                            ) {
                                selectedType = selectedType == type.rawValue ? nil : type.rawValue
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)

                // Content
                if vitals.isEmpty {
                    emptyState
                } else if filteredVitals.isEmpty {
                    Text("No results")
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
                        ForEach(groupedVitals, id: \.0) { dateLabel, records in
                            VStack(alignment: .leading, spacing: 10) {
                                SectionLabel(title: dateLabel, dotColor: Color.roseStart)
                                    .padding(.horizontal, 20)

                                VStack(spacing: 10) {
                                    ForEach(records) { vital in
                                        Button { selected = vital } label: {
                                            VitalCardRow(vital: vital)
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
        .sheet(isPresented: $showAdd) { AddVitalView() }
        .sheet(item: $selected) { vital in
            VitalDetailSheet(vital: vital) {
                modelContext.delete(vital)
                selected = nil
            }
        }
        .alert(
            importResult.flatMap {
                if case .success = $0 { return "Import Complete" }
                return "Import Failed"
            } ?? "",
            isPresented: Binding(
                get: { importResult != nil },
                set: { if !$0 { importResult = nil } }
            )
        ) {
            Button("OK") { importResult = nil }
        } message: {
            switch importResult {
            case .success(let count):
                if count > 0 {
                    Text("Imported \(count) new reading\(count == 1 ? "" : "s") from Apple Health.")
                } else {
                    Text("No new readings to import.")
                }
            case .error(let msg):
                Text(msg)
            case nil:
                EmptyView()
            }
        }
    }

    private func importFromHealthKit() async {
        isImporting = true
        defer { isImporting = false }

        do {
            try await healthKitService.requestAuthorization()
            let imported = try await healthKitService.fetchRecentVitals()

            var insertedCount = 0
            for iv in imported {
                let isDuplicate = vitals.contains { existing in
                    existing.type == iv.type &&
                    abs(existing.recordedAt.timeIntervalSince(iv.recordedAt)) < 60
                }
                if !isDuplicate {
                    let record = VitalRecord(
                        type: iv.type,
                        value: iv.value,
                        secondaryValue: iv.secondaryValue,
                        unit: iv.unit,
                        source: "healthkit",
                        recordedAt: iv.recordedAt
                    )
                    modelContext.insert(record)
                    insertedCount += 1
                }
            }

            importResult = .success(insertedCount)
        } catch {
            importResult = .error(error.localizedDescription)
        }
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 28))
                .foregroundStyle(Color.roseStart.opacity(0.4))
                .frame(width: 64, height: 64)
                .background(Color.roseStart.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            Text("No vitals logged")
                .font(.system(size: 15))
                .foregroundStyle(Color.mutedFg)
            Text("Tap + to log your first reading")
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

// MARK: - Vital Card Row (self-contained card)

struct VitalCardRow: View {
    let vital: VitalRecord

    var body: some View {
        let style = VitalTypeStyle.forType(vital.type)
        let vitalType = VitalType(rawValue: vital.type)
        let formattedValue = vitalType?.formatValue(vital.value, secondary: vital.secondaryValue) ?? "\(Int(vital.value))"

        HStack(spacing: 0) {
            // Color stripe
            Rectangle()
                .fill(
                    LinearGradient(colors: style.gradient, startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 6)

            HStack(spacing: 14) {
                // Type icon
                Image(systemName: style.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(style.color)
                    .frame(width: 46, height: 46)
                    .background(style.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(vital.type)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.nearBlack)
                        .lineLimit(1)
                    Text("\(formattedValue) \(vital.unit)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.mutedFg)
                }

                Spacer()

                // Time badge
                HStack(spacing: 4) {
                    if vital.source == "healthkit" {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.roseStart.opacity(0.6))
                    }
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.mutedFg)
                    Text(vital.recordedAt, format: .dateTime.hour().minute())
                        .font(.system(size: 11))
                        .foregroundStyle(Color.mutedFg)
                        .lineLimit(1)
                        .fixedSize()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.bg)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .warmShadow()
    }
}

// MARK: - Add Vital View

struct AddVitalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var type: VitalType = .bloodPressure
    @State private var value = ""
    @State private var secondaryValue = ""
    @State private var recordedAt = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FormToolbar(title: "Log Vital", gradient: [Color.roseStart, Color.roseEnd],
                            saveDisabled: value.trimmingCharacters(in: .whitespaces).isEmpty,
                            onCancel: { dismiss() }, onSave: { save() })
                ScrollView {
                    VStack(spacing: 20) {
                        FormHeader(
                            icon: "waveform.path.ecg",
                            title: "Log Vital",
                            subtitle: "Record a health measurement",
                            gradient: [.roseStart, .roseEnd]
                        )
                        FormSection(title: "Type", dotColor: Color.roseStart) {
                            FormChipPicker(
                                selection: $type,
                                options: VitalType.allCases,
                                labels: { $0.rawValue },
                                gradient: [.roseStart, .roseEnd],
                                icons: { VitalTypeStyle.forType($0.rawValue).icon }
                            )
                        }
                        FormSection(title: "Value", dotColor: Color.roseStart) {
                            if type.hasDualValue {
                                HStack(spacing: 8) {
                                    FormTextField(label: "Systolic", text: $value, placeholder: "120", keyboardType: .numberPad)
                                    Text("/")
                                        .font(.system(size: 20, weight: .light))
                                        .foregroundStyle(Color.mutedFg)
                                    FormTextField(label: "Diastolic", text: $secondaryValue, placeholder: "80", keyboardType: .numberPad)
                                }
                            } else {
                                FormTextField(
                                    label: type.unit,
                                    text: $value,
                                    placeholder: "Enter value",
                                    icon: VitalTypeStyle.forType(type.rawValue).icon,
                                    keyboardType: type == .weight ? .decimalPad : .numberPad
                                )
                            }
                        }
                        FormSection(title: "When", dotColor: Color.roseStart) {
                            HStack(spacing: 10) {
                                Image(systemName: "calendar.clock")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.primaryTeal)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Date & Time")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.mutedFg)
                                    DatePicker("", selection: $recordedAt)
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
                        FormSection(title: "Notes") {
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

    private func save() {
        guard let v = Double(value.trimmingCharacters(in: .whitespaces)) else { return }
        let sv: Double? = type.hasDualValue ? Double(secondaryValue.trimmingCharacters(in: .whitespaces)) : nil

        let record = VitalRecord(
            type: type.rawValue,
            value: v,
            secondaryValue: sv,
            unit: type.unit,
            notes: notes.trimmingCharacters(in: .whitespaces),
            recordedAt: recordedAt
        )
        modelContext.insert(record)
        dismiss()
    }
}

// MARK: - Vital Detail Sheet

struct VitalDetailSheet: View {
    let vital: VitalRecord
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \VitalRecord.recordedAt) private var allVitals: [VitalRecord]
    @State private var showEdit = false

    private var vitalType: VitalType? { VitalType(rawValue: vital.type) }
    private var style: VitalTypeStyle { VitalTypeStyle.forType(vital.type) }
    private var isFromHealthKit: Bool { vital.source == "healthkit" }
    private var formattedValue: String {
        vitalType?.formatValue(vital.value, secondary: vital.secondaryValue) ?? "\(Int(vital.value))"
    }

    private var trendData: [VitalRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return allVitals.filter { $0.type == vital.type && $0.recordedAt >= cutoff }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DetailToolbar(title: "Vital Details", showEdit: !isFromHealthKit,
                              onDone: { dismiss() }, onEdit: { showEdit = true })
                ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: style.icon)
                            .font(.system(size: 32))
                            .foregroundStyle(style.color)
                            .frame(width: 72, height: 72)
                            .background(style.color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        Text(formattedValue)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.nearBlack)
                        Text(vital.unit)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.mutedFg)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)

                    // Details
                    VStack(spacing: 0) {
                        detailRow(label: "Type", value: vital.type)
                        Divider().padding(.leading, 16)
                        detailRow(label: "Date", value: vital.recordedAt.formatted(.dateTime.month(.wide).day().year()))
                        Divider().padding(.leading, 16)
                        detailRow(label: "Time", value: vital.recordedAt.formatted(.dateTime.hour().minute()))
                        if !vital.notes.isEmpty {
                            Divider().padding(.leading, 16)
                            detailRow(label: "Notes", value: vital.notes)
                        }
                        if isFromHealthKit {
                            Divider().padding(.leading, 16)
                            HStack {
                                Text("Source")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.mutedFg)
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.roseStart)
                                    Text("Apple Health")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.nearBlack)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }
                    .background(Color.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)

                    // 30-day trend chart
                    if trendData.count >= 2 {
                        trendChart
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    }

                    // Delete button (hidden for HealthKit records)
                    if !isFromHealthKit {
                        Button {
                            onDelete()
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                Text("Remove Reading")
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
            }
            .background(Color.cardBg)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showEdit) {
                EditVitalView(vital: vital)
            }
            }
            .background(Color.cardBg)
            .toolbar(.hidden, for: .navigationBar)
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(24)
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("30-Day Trend")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.nearBlack)

            Chart {
                if vitalType?.hasDualValue == true {
                    ForEach(trendData) { record in
                        LineMark(
                            x: .value("Date", record.recordedAt),
                            y: .value("Systolic", record.value),
                            series: .value("Series", "Systolic")
                        )
                        .foregroundStyle(style.color)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", record.recordedAt),
                            y: .value("Systolic", record.value)
                        )
                        .foregroundStyle(style.color)
                        .symbolSize(20)

                        if let dia = record.secondaryValue {
                            LineMark(
                                x: .value("Date", record.recordedAt),
                                y: .value("Diastolic", dia),
                                series: .value("Series", "Diastolic")
                            )
                            .foregroundStyle(style.color.opacity(0.5))
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", record.recordedAt),
                                y: .value("Diastolic", dia)
                            )
                            .foregroundStyle(style.color.opacity(0.5))
                            .symbolSize(20)
                        }
                    }
                } else {
                    ForEach(trendData) { record in
                        LineMark(
                            x: .value("Date", record.recordedAt),
                            y: .value("Value", record.value)
                        )
                        .foregroundStyle(style.color)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", record.recordedAt),
                            y: .value("Value", record.value)
                        )
                        .foregroundStyle(style.color)
                        .symbolSize(20)
                    }

                    if let avg = trendData.isEmpty ? nil : trendData.map(\.value).reduce(0, +) / Double(trendData.count) {
                        RuleMark(y: .value("Average", avg))
                            .foregroundStyle(Color.mutedFg.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) {
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 9))
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisValueLabel()
                        .font(.system(size: 10))
                    AxisGridLine()
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(Color.bg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

// MARK: - Edit Vital View

struct EditVitalView: View {
    let vital: VitalRecord
    @Environment(\.dismiss) private var dismiss

    @State private var value: String
    @State private var secondaryValue: String
    @State private var recordedAt: Date
    @State private var notes: String

    init(vital: VitalRecord) {
        self.vital = vital
        _value = State(initialValue: vital.type == "Weight"
            ? (vital.value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(vital.value))" : String(format: "%.1f", vital.value))
            : "\(Int(vital.value))")
        _secondaryValue = State(initialValue: vital.secondaryValue.map { "\(Int($0))" } ?? "")
        _recordedAt = State(initialValue: vital.recordedAt)
        _notes = State(initialValue: vital.notes)
    }

    private var vitalType: VitalType? { VitalType(rawValue: vital.type) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FormToolbar(title: "Edit Vital", gradient: [Color.roseStart, Color.roseEnd],
                            saveDisabled: value.trimmingCharacters(in: .whitespaces).isEmpty,
                            onCancel: { dismiss() }, onSave: { save() })
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Type", dotColor: Color.roseStart) {
                            let style = VitalTypeStyle.forType(vital.type)
                            HStack(spacing: 10) {
                                Image(systemName: style.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(style.color)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Type")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.mutedFg)
                                    Text(vital.type)
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.nearBlack)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.mutedBg.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        FormSection(title: "Value", dotColor: Color.roseStart) {
                            if vitalType?.hasDualValue == true {
                                HStack(spacing: 8) {
                                    FormTextField(label: "Systolic", text: $value, placeholder: "120", keyboardType: .numberPad)
                                    Text("/")
                                        .font(.system(size: 20, weight: .light))
                                        .foregroundStyle(Color.mutedFg)
                                    FormTextField(label: "Diastolic", text: $secondaryValue, placeholder: "80", keyboardType: .numberPad)
                                }
                            } else {
                                FormTextField(
                                    label: vital.unit,
                                    text: $value,
                                    placeholder: "Enter value",
                                    icon: VitalTypeStyle.forType(vital.type).icon,
                                    keyboardType: vital.type == "Weight" ? .decimalPad : .numberPad
                                )
                            }
                        }
                        FormSection(title: "When", dotColor: Color.roseStart) {
                            HStack(spacing: 10) {
                                Image(systemName: "calendar.clock")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.primaryTeal)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Date & Time")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.mutedFg)
                                    DatePicker("", selection: $recordedAt)
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
                        FormSection(title: "Notes") {
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

    private func save() {
        guard let v = Double(value.trimmingCharacters(in: .whitespaces)) else { return }
        vital.value = v
        if vitalType?.hasDualValue == true {
            vital.secondaryValue = Double(secondaryValue.trimmingCharacters(in: .whitespaces))
        }
        vital.recordedAt = recordedAt
        vital.notes = notes.trimmingCharacters(in: .whitespaces)
        dismiss()
    }
}
