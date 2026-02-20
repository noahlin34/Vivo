//
//  MedicationsView.swift
//  Vivo
//

import SwiftUI
import SwiftData

struct MedicationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medication.scheduledTime) private var medications: [Medication]
    @State private var showAdd = false
    @State private var selected: Medication? = nil

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
                .padding(.top, 16)
                .padding(.bottom, 20)

                // Content
                if medications.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(medications.enumerated()), id: \.element.id) { index, med in
                            Button { selected = med } label: {
                                MedicationCardRow(medication: med)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { modelContext.delete(med) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            if index < medications.count - 1 {
                                Divider().padding(.leading, 80)
                            }
                        }
                    }
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .warmShadow()
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color.bg)
        .sheet(isPresented: $showAdd) { AddMedicationView() }
        .sheet(item: $selected) { med in
            MedicationDetailSheet(medication: med) {
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

    private var color: Color { .medColor(medication.colorIndex) }

    var body: some View {
        NavigationStack {
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
                }
                .background(Color.bg)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)

                Spacer()

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
            .navigationTitle("Medication Details")
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

    func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.mutedFg)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(Color.nearBlack)
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
    @State private var colorIndex = 0

    private let frequencies = ["Once daily", "Twice daily", "Three times daily", "As needed"]
    private let colorNames = ["Teal", "Green", "Amber", "Purple", "Cyan", "Rose"]
    private let colorHexes = Color.medHexColors

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(LinearGradient(colors: [.tealStart, .tealEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Text("Add Medication")
                            .font(.headline)
                    }
                } header: {
                    EmptyView()
                }

                Section("Medication Info") {
                    TextField("Name", text: $name)
                    TextField("Dosage (e.g. 10mg)", text: $dosage)
                }

                Section("Schedule") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { Text($0) }
                    }
                    DatePicker("Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                }

                Section("Color") {
                    Picker("Color", selection: $colorIndex) {
                        ForEach(0..<colorNames.count, id: \.self) { i in
                            HStack {
                                Circle()
                                    .fill(Color(hex: colorHexes[i]))
                                    .frame(width: 16, height: 16)
                                Text(colorNames[i])
                            }
                            .tag(i)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationCornerRadius(24)
    }

    private func save() {
        modelContext.insert(Medication(
            name: name.trimmingCharacters(in: .whitespaces),
            dosage: dosage.trimmingCharacters(in: .whitespaces),
            frequency: frequency,
            scheduledTime: scheduledTime,
            colorIndex: colorIndex
        ))
        dismiss()
    }
}
