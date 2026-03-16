//
//  DoctorsView.swift
//  Vivo
//

import SwiftUI
import SwiftData

struct DoctorsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Doctor.createdAt) private var doctors: [Doctor]
    @State private var showAdd = false
    @State private var selected: Doctor? = nil
    @State private var searchText = ""
    @State private var doctorToDelete: Doctor? = nil

    private var filteredDoctors: [Doctor] {
        guard !searchText.isEmpty else { return doctors }
        return doctors.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.specialty.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Doctors")
                            .font(.system(size: 28, weight: .regular, design: .serif))
                            .foregroundStyle(Color.nearBlack)
                        Text("\(doctors.count) doctor\(doctors.count == 1 ? "" : "s") in your care team")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mutedFg)
                    }
                    Spacer()
                    GradientAddButton(gradient: [.amberStart, .amberEnd]) { showAdd = true }
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 20)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.mutedFg.opacity(0.6))
                    TextField("Search doctors...", text: $searchText)
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
                if doctors.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(filteredDoctors) { doc in
                            Button { selected = doc } label: {
                                DoctorCardRow(doctor: doc)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    doctorToDelete = doc
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
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
            "Remove \(doctorToDelete?.name ?? "Doctor")?",
            isPresented: Binding(get: { doctorToDelete != nil }, set: { if !$0 { doctorToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let doc = doctorToDelete {
                    modelContext.delete(doc)
                    doctorToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { doctorToDelete = nil }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $showAdd) { AddDoctorView() }
        .sheet(item: $selected) { doc in
            DoctorDetailSheet(doctor: doc) {
                modelContext.delete(doc)
                selected = nil
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
            Text("No doctors added")
                .font(.system(size: 15))
                .foregroundStyle(Color.mutedFg)
            Text("Tap + to add your first doctor")
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

// MARK: - Doctor Detail Sheet

struct DoctorDetailSheet: View {
    let doctor: Doctor
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var selectedAppt: Appointment? = nil

    private var sortedAppointments: [Appointment] {
        (doctor.appointments ?? []).sorted { $0.date < $1.date }
    }
    private var upcomingAppts: [Appointment] {
        let today = Calendar.current.startOfDay(for: Date())
        return sortedAppointments.filter { $0.date >= today }
    }
    private var pastAppts: [Appointment] {
        let today = Calendar.current.startOfDay(for: Date())
        return Array(sortedAppointments.filter { $0.date < today }.reversed())
    }
    private var hasAppointments: Bool { !(doctor.appointments ?? []).isEmpty }

    var body: some View {
        let style = SpecialtyStyle.forSpecialty(doctor.specialty)
        let initial = doctor.name.split(separator: " ").last?.first.map(String.init) ?? "D"

        return NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 16) {
                        ZStack {
                            LinearGradient(colors: style.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            Text(initial)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        VStack(alignment: .leading, spacing: 6) {
                            Text(doctor.name)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(Color.nearBlack)
                            Text(doctor.specialty)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(style.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(style.color.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)

                    // Contact rows
                    VStack(spacing: 10) {
                        if !doctor.phone.isEmpty {
                            let digits = doctor.phone.filter { $0.isNumber || $0 == "+" }
                            if let url = URL(string: "tel://\(digits)") {
                                Link(destination: url) {
                                    contactRow(icon: "phone.fill", iconColor: Color.primaryTeal, label: "Phone", value: doctor.phone)
                                }
                                .foregroundStyle(Color.nearBlack)
                            } else {
                                contactRow(icon: "phone", iconColor: Color.primaryTeal, label: "Phone", value: doctor.phone)
                            }
                        }
                        if !doctor.email.isEmpty {
                            if let url = URL(string: "mailto:\(doctor.email)") {
                                Link(destination: url) {
                                    contactRow(icon: "envelope.fill", iconColor: Color.cyanStart, label: "Email", value: doctor.email)
                                }
                                .foregroundStyle(Color.nearBlack)
                            } else {
                                contactRow(icon: "envelope", iconColor: Color.cyanStart, label: "Email", value: doctor.email)
                            }
                        }
                        if !doctor.address.isEmpty {
                            contactRow(icon: "mappin", iconColor: Color.amberStart, label: "Address", value: doctor.address)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Appointments history
                    if hasAppointments {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Appointments")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.nearBlack)
                                Spacer()
                                Text("\((doctor.appointments ?? []).count) total")
                                    .font(.system(size: 12))
                                    .foregroundStyle(style.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(style.color.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal, 20)

                            if !upcomingAppts.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    SectionLabel(title: "Upcoming", dotColor: Color.cyanStart)
                                        .padding(.horizontal, 20)
                                    VStack(spacing: 8) {
                                        ForEach(upcomingAppts) { appt in
                                            Button { selectedAppt = appt } label: {
                                                apptRow(appt, isPast: false)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }

                            if !pastAppts.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    SectionLabel(title: "Past", dotColor: Color.mutedFg)
                                        .padding(.horizontal, 20)
                                    VStack(spacing: 8) {
                                        ForEach(pastAppts) { appt in
                                            Button { selectedAppt = appt } label: {
                                                apptRow(appt, isPast: true)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.top, 20)
                    }

                    // Delete button
                    Button {
                        onDelete()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("Remove Doctor")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.destructive)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.destructive.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.cardBg)
            .navigationTitle("Doctor Details")
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
                EditDoctorView(doctor: doctor)
            }
            .sheet(item: $selectedAppt) { appt in
                AppointmentDetailSheet(appointment: appt) {
                    AppointmentNotifications.cancel(for: appt)
                    appt.modelContext?.delete(appt)
                    selectedAppt = nil
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(24)
    }

    func apptRow(_ appt: Appointment, isPast: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 1) {
                Text(appt.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(isPast ? Color.mutedFg : .white.opacity(0.85))
                Text(appt.date.formatted(.dateTime.day()))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isPast ? Color.mutedFg : .white)
            }
            .frame(width: 40, height: 40)
            .background {
                if isPast {
                    Color.mutedBg
                } else {
                    LinearGradient(colors: [Color.cyanStart, Color.cyanEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(appt.title)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.nearBlack)
                    .lineLimit(1)
                Text(appt.date.formatted(.dateTime.month(.wide).day().year()) + " · " + appt.date.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mutedFg)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.mutedFg.opacity(0.3))
        }
        .padding(12)
        .background(Color.bg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(isPast ? 0.65 : 1.0)
    }

    func contactRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
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

// MARK: - Add Doctor Sheet

struct AddDoctorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var specialty = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var address = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(LinearGradient(colors: [.amberStart, .amberEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Text("Add Doctor")
                            .font(.headline)
                    }
                }

                Section("Doctor Info") {
                    TextField("Full Name", text: $name)
                    TextField("Specialty", text: $specialty)
                }

                Section("Contact") {
                    TextField("Phone", text: $phone).keyboardType(.phonePad)
                    TextField("Email", text: $email).keyboardType(.emailAddress)
                    TextField("Address", text: $address)
                }
            }
            .navigationTitle("Add Doctor")
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
        modelContext.insert(Doctor(
            name: name.trimmingCharacters(in: .whitespaces),
            specialty: specialty.trimmingCharacters(in: .whitespaces),
            phone: phone.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            address: address.trimmingCharacters(in: .whitespaces)
        ))
        dismiss()
    }
}

// MARK: - Edit Doctor Sheet

struct EditDoctorView: View {
    let doctor: Doctor
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var specialty: String
    @State private var phone: String
    @State private var email: String
    @State private var address: String

    init(doctor: Doctor) {
        self.doctor = doctor
        _name = State(initialValue: doctor.name)
        _specialty = State(initialValue: doctor.specialty)
        _phone = State(initialValue: doctor.phone)
        _email = State(initialValue: doctor.email)
        _address = State(initialValue: doctor.address)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Doctor Info") {
                    TextField("Full Name", text: $name)
                    TextField("Specialty", text: $specialty)
                }
                Section("Contact") {
                    TextField("Phone", text: $phone).keyboardType(.phonePad)
                    TextField("Email", text: $email).keyboardType(.emailAddress)
                    TextField("Address", text: $address)
                }
            }
            .navigationTitle("Edit Doctor")
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
        doctor.name = name.trimmingCharacters(in: .whitespaces)
        doctor.specialty = specialty.trimmingCharacters(in: .whitespaces)
        doctor.phone = phone.trimmingCharacters(in: .whitespaces)
        doctor.email = email.trimmingCharacters(in: .whitespaces)
        doctor.address = address.trimmingCharacters(in: .whitespaces)
        dismiss()
    }
}
