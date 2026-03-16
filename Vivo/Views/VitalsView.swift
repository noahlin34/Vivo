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
                        Text("\(vitals.count) reading\(vitals.count == 1 ? "" : "s") logged")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mutedFg)
                    }
                    Spacer()
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
            Form {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(LinearGradient(colors: [.roseStart, .roseEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Text("Log Vital")
                            .font(.headline)
                    }
                }

                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(VitalType.allCases, id: \.self) { t in
                            HStack {
                                Image(systemName: t.icon)
                                    .foregroundStyle(t.color)
                                Text(t.rawValue)
                            }
                            .tag(t)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Value") {
                    if type.hasDualValue {
                        HStack {
                            TextField("Systolic", text: $value)
                                .keyboardType(.numberPad)
                            Text("/")
                                .foregroundStyle(Color.mutedFg)
                            TextField("Diastolic", text: $secondaryValue)
                                .keyboardType(.numberPad)
                        }
                        Text(type.unit)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mutedFg)
                    } else {
                        HStack {
                            TextField("Value", text: $value)
                                .keyboardType(.decimalPad)
                            Text(type.unit)
                                .foregroundStyle(Color.mutedFg)
                        }
                    }
                }

                Section("When") {
                    DatePicker("Date & Time", selection: $recordedAt)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes)
                }
            }
            .navigationTitle("Log Vital")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(value.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
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
    private var formattedValue: String {
        vitalType?.formatValue(vital.value, secondary: vital.secondaryValue) ?? "\(Int(vital.value))"
    }

    private var trendData: [VitalRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return allVitals.filter { $0.type == vital.type && $0.recordedAt >= cutoff }
    }

    var body: some View {
        NavigationStack {
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

                    // Delete button
                    Button {
                        onDelete()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("Remove Reading")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "DC2626"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "DC2626").opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.cardBg)
            .navigationTitle("Vital Details")
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
                EditVitalView(vital: vital)
            }
        }
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
            Form {
                Section("Value") {
                    if vitalType?.hasDualValue == true {
                        HStack {
                            TextField("Systolic", text: $value)
                                .keyboardType(.numberPad)
                            Text("/")
                                .foregroundStyle(Color.mutedFg)
                            TextField("Diastolic", text: $secondaryValue)
                                .keyboardType(.numberPad)
                        }
                        Text(vital.unit)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mutedFg)
                    } else {
                        HStack {
                            TextField("Value", text: $value)
                                .keyboardType(.decimalPad)
                            Text(vital.unit)
                                .foregroundStyle(Color.mutedFg)
                        }
                    }
                }

                Section("When") {
                    DatePicker("Date & Time", selection: $recordedAt)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes)
                }
            }
            .navigationTitle("Edit Vital")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(value.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
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
