//
//  SharedComponents.swift
//  Vivo
//

import SwiftUI
import UIKit

// MARK: - Adaptive Color Helper

extension Color {
    /// Creates a color that adapts between light and dark mode using hex strings.
    /// Uses UIColor dynamic provider — NOT `UIColor(Color(hex:))` (see CLAUDE.md).
    static func adaptive(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return uiColor(hex: hex)
        })
    }

    /// Parses a hex string into a UIColor directly (no Color(hex:) round-trip).
    private static func uiColor(hex: String) -> UIColor {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8) & 0xFF) / 255
        let b = CGFloat(int & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Design Tokens

extension Color {
    // Background and surface (adaptive)
    static let bg = Color.adaptive(light: "F6F2EC", dark: "1C1816")
    static let cardBg = Color.adaptive(light: "FFFFFF", dark: "2A2520")
    static let mutedBg = Color.adaptive(light: "E8E2D9", dark: "231F1B")

    // Text (adaptive)
    static let nearBlack = Color.adaptive(light: "1A1612", dark: "EBE6DF")
    static let mutedFg = Color.adaptive(light: "8C8279", dark: "9E958C")

    // Primary
    static let primaryTeal = Color(hex: "0D7C66")

    // Destructive (adaptive — brighter red in dark mode)
    static let destructive = Color.adaptive(light: "DC2626", dark: "EF4444")

    // Gradient palette
    static let tealStart = Color(hex: "0D7C66")
    static let tealEnd = Color(hex: "059669")
    static let amberStart = Color(hex: "D97706")
    static let amberEnd = Color(hex: "F59E0B")
    static let cyanStart = Color(hex: "0891B2")
    static let cyanEnd = Color(hex: "06B6D4")
    static let purpleStart = Color(hex: "7C3AED")
    static let purpleEnd = Color(hex: "A78BFA")
    static let roseStart = Color(hex: "E11D48")
    static let roseEnd = Color(hex: "F43F5E")

    // Medication color palette (by colorIndex 0–5)
    static let medHexColors: [String] = [
        "0D7C66", "059669", "D97706", "7C3AED", "0891B2", "E11D48"
    ]
    static func medColor(_ index: Int) -> Color {
        Color(hex: medHexColors[max(0, min(index, medHexColors.count - 1))])
    }

    // Hex initializer
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

// MARK: - Specialty / Category Styles

struct SpecialtyStyle {
    let color: Color
    let gradient: [Color]

    static func forSpecialty(_ s: String) -> SpecialtyStyle {
        switch s {
        case "Primary Care":   return .init(color: Color(hex: "0D7C66"), gradient: [Color(hex: "0D7C66"), Color(hex: "059669")])
        case "Cardiologist":   return .init(color: Color(hex: "E11D48"), gradient: [Color(hex: "E11D48"), Color(hex: "F43F5E")])
        case "Endocrinologist":return .init(color: Color(hex: "7C3AED"), gradient: [Color(hex: "7C3AED"), Color(hex: "A78BFA")])
        case "Dermatologist":  return .init(color: Color(hex: "D97706"), gradient: [Color(hex: "D97706"), Color(hex: "F59E0B")])
        case "Neurologist":    return .init(color: Color(hex: "6366F1"), gradient: [Color(hex: "6366F1"), Color(hex: "818CF8")])
        case "Orthopedist":    return .init(color: Color(hex: "059669"), gradient: [Color(hex: "059669"), Color(hex: "34D399")])
        case "Pediatrician":   return .init(color: Color(hex: "0891B2"), gradient: [Color(hex: "0891B2"), Color(hex: "22D3EE")])
        default:               return .init(color: Color(hex: "0D7C66"), gradient: [Color(hex: "0D7C66"), Color(hex: "059669")])
        }
    }
}

struct CategoryStyle {
    let color: Color
    let gradient: [Color]

    static func forCategory(_ c: String) -> CategoryStyle {
        switch c {
        case "Vitals":      return .init(color: Color(hex: "E11D48"), gradient: [Color(hex: "E11D48"), Color(hex: "F43F5E")])
        case "Medications": return .init(color: Color(hex: "0D7C66"), gradient: [Color(hex: "0D7C66"), Color(hex: "059669")])
        case "Lifestyle":   return .init(color: Color(hex: "059669"), gradient: [Color(hex: "059669"), Color(hex: "34D399")])
        case "Questions":   return .init(color: Color(hex: "D97706"), gradient: [Color(hex: "D97706"), Color(hex: "F59E0B")])
        case "Symptoms":    return .init(color: Color(hex: "7C3AED"), gradient: [Color(hex: "7C3AED"), Color(hex: "A78BFA")])
        default:            return .init(color: Color(hex: "8C8279"), gradient: [Color(hex: "8C8279"), Color(hex: "A8A29E")])
        }
    }
}

struct VitalTypeStyle {
    let color: Color
    let gradient: [Color]
    let icon: String

    static func forType(_ t: String) -> VitalTypeStyle {
        switch t {
        case "Blood Pressure": return .init(color: Color(hex: "E11D48"), gradient: [Color(hex: "E11D48"), Color(hex: "F43F5E")], icon: "heart.fill")
        case "Weight":         return .init(color: Color(hex: "0891B2"), gradient: [Color(hex: "0891B2"), Color(hex: "06B6D4")], icon: "scalemass.fill")
        case "Heart Rate":     return .init(color: Color(hex: "E11D48"), gradient: [Color(hex: "E11D48"), Color(hex: "F43F5E")], icon: "waveform.path.ecg")
        case "Blood Sugar":    return .init(color: Color(hex: "7C3AED"), gradient: [Color(hex: "7C3AED"), Color(hex: "A78BFA")], icon: "drop.fill")
        default:               return .init(color: Color(hex: "E11D48"), gradient: [Color(hex: "E11D48"), Color(hex: "F43F5E")], icon: "heart.fill")
        }
    }
}

// MARK: - Shadow Helpers

extension View {
    func warmShadow() -> some View {
        shadow(color: Color(hex: "1A1612").opacity(0.06), radius: 8, x: 0, y: 2)
    }
    func warmShadowLg() -> some View {
        shadow(color: Color(hex: "1A1612").opacity(0.08), radius: 16, x: 0, y: 4)
    }
}

// MARK: - Form Toolbars

struct FormToolbar: View {
    let title: String
    let gradient: [Color]
    var saveDisabled: Bool = false
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundStyle(Color.nearBlack)
            HStack {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.mutedFg)
                }
                Spacer()
                Button(action: onSave) {
                    Text("Save")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(Capsule())
                }
                .disabled(saveDisabled)
                .opacity(saveDisabled ? 0.5 : 1.0)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

struct DetailToolbar: View {
    let title: String
    var showEdit: Bool = true
    let onDone: () -> Void
    var onEdit: () -> Void = {}

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundStyle(Color.nearBlack)
            HStack {
                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.mutedFg)
                }
                Spacer()
                if showEdit {
                    Button(action: onEdit) {
                        Text("Edit")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.primaryTeal)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

// MARK: - Gradient Add Button

struct GradientAddButton: View {
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - Gradient Date Badge

struct GradientDateBadge: View {
    let date: Date
    var isPast: Bool = false
    var isToday: Bool = false

    var body: some View {
        VStack(spacing: 1) {
            Text(date.formatted(.dateTime.month(.abbreviated)).uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isPast ? Color.mutedFg : .white.opacity(0.85))
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(isPast ? Color.mutedFg : .white)
        }
        .frame(width: 52, height: 52)
        .background {
            if isPast {
                Color.mutedBg.opacity(0.6)
            } else if isToday {
                LinearGradient(colors: [Color.amberStart, Color.amberEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                LinearGradient(colors: [Color.tealStart, Color.cyanStart], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Medication Card Row (self-contained card)

struct MedicationCardRow: View {
    let medication: Medication
    var onToggle: (() -> Void)? = nil

    private var color: Color { .medColor(medication.colorIndex) }
    private var isTaken: Bool { medication.isTakenToday }

    @ViewBuilder
    private var doseIndicator: some View {
        let required = medication.dosesRequired
        let taken = medication.dosesTakenToday
        if required == 0 {
            // "As needed" — show dose count when logged, always show + to log more
            HStack(spacing: 5) {
                if taken > 0 {
                    Text("×\(taken)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(color)
                        .monospacedDigit()
                }
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(color.opacity(taken > 0 ? 1.0 : 0.65))
            }
        } else if required == 1 {
            // Once daily — same satisfying checkmark as before
            Image(systemName: isTaken ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundStyle(isTaken ? color : Color.mutedFg.opacity(0.35))
        } else {
            // Twice / Three times daily — filled progress dots
            HStack(spacing: 5) {
                ForEach(0..<required, id: \.self) { i in
                    Circle()
                        .fill(i < taken ? color : Color.mutedFg.opacity(0.25))
                        .frame(width: 9, height: 9)
                }
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Color stripe (6px — matches Figma w-1.5)
            Rectangle()
                .fill(
                    LinearGradient(colors: [color, color.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 6)

            HStack(spacing: 14) {
                // Pill icon — dims when taken
                Image(systemName: "pill.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(color.opacity(isTaken ? 0.35 : 1.0))
                    .frame(width: 46, height: 46)
                    .background(color.opacity(isTaken ? 0.05 : 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(medication.name)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.nearBlack)
                        .strikethrough(isTaken, color: Color.mutedFg)
                        .lineLimit(1)
                    Text("\(medication.dosage) · \(medication.frequency)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.mutedFg)
                    if medication.isLowSupply, let days = medication.daysRemaining {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                            Text(days == 0 ? "Refill needed" : "~\(days)d left")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(days <= 3 ? Color.destructive : Color.amberStart)
                        .padding(.top, 1)
                    }
                }

                Spacer()

                // Time badge (hidden for "As needed" meds)
                if medication.frequency != "As needed" {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.mutedFg)
                        Text(medication.scheduledTime, format: .dateTime.hour().minute())
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

                // Dose indicator — only shown when onToggle is provided (MedicationsView)
                if let toggle = onToggle {
                    Button(action: toggle) {
                        doseIndicator
                    }
                    .buttonStyle(.plain)
                    .frame(height: 28)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .warmShadow()
        .opacity(isTaken ? 0.75 : 1.0)
    }
}

// MARK: - Doctor Card Row (self-contained card)

struct DoctorCardRow: View {
    let doctor: Doctor

    var body: some View {
        let style = SpecialtyStyle.forSpecialty(doctor.specialty)
        let initial = doctor.name.split(separator: " ").last?.first.map(String.init) ?? "D"

        HStack(spacing: 14) {
            // Gradient avatar
            ZStack {
                LinearGradient(colors: style.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                Text(initial)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(doctor.name)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.nearBlack)
                    .lineLimit(1)

                Text(doctor.specialty)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(style.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(style.color.opacity(0.1))
                    .clipShape(Capsule())
            }

            Spacer()

            // Phone icon button
            Image(systemName: "phone")
                .font(.system(size: 14))
                .foregroundStyle(Color.primaryTeal)
                .frame(width: 32, height: 32)
                .background(Color.primaryTeal.opacity(0.08))
                .clipShape(Circle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .warmShadow()
    }
}

// MARK: - Appointment Card Row (self-contained card)

struct AppointmentCardRow: View {
    let appointment: Appointment
    /// Pass true in the Appointments tab to show amber "Today" badge; false in Home preview
    var showTodayBadge: Bool = false

    var body: some View {
        let isPast = appointment.date < Calendar.current.startOfDay(for: Date())
        let isToday = Calendar.current.isDateInToday(appointment.date)
        let showAmber = showTodayBadge && isToday

        VStack(spacing: 0) {
            // Amber top stripe for today
            if showAmber {
                LinearGradient(colors: [.amberStart, .amberEnd], startPoint: .leading, endPoint: .trailing)
                    .frame(height: 2)
            }

            HStack(spacing: 14) {
                GradientDateBadge(date: appointment.date, isPast: isPast, isToday: showAmber)

                VStack(alignment: .leading, spacing: 3) {
                    Text(appointment.title)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.nearBlack)
                        .lineLimit(1)
                    Text(appointment.displayDoctorName)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.mutedFg)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.mutedFg.opacity(0.6))
                        Text(appointment.date.formatted(.dateTime.hour().minute()))
                            .font(.system(size: 11))
                            .foregroundStyle(Color.mutedFg.opacity(0.8))
                    }
                }

                Spacer()

                if showAmber {
                    Text("Today")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.amberStart)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.amberStart.opacity(0.1))
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.mutedFg.opacity(0.3))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .warmShadow()
        .opacity(isPast ? 0.55 : 1)
    }
}

// MARK: - Note Card

struct NoteCard: View {
    let note: HealthNote
    let onDelete: () -> Void

    var body: some View {
        let style = CategoryStyle.forCategory(note.category)

        VStack(alignment: .leading, spacing: 0) {
            // Gradient top accent bar
            LinearGradient(colors: style.gradient, startPoint: .leading, endPoint: .trailing)
                .frame(height: 4)

            VStack(alignment: .leading, spacing: 8) {
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
                    .lineLimit(3)
                Text(note.createdAt, format: .dateTime.month(.wide).day().year())
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mutedFg.opacity(0.5))
            }
            .padding(16)
        }
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .warmShadow()
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Category Chip (filter)

struct CategoryChip: View {
    let title: String
    let gradient: [Color]
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : Color.mutedFg)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    if isSelected {
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        Color.cardBg
                    }
                }
                .clipShape(Capsule())
                .warmShadow()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Label

struct SectionLabel: View {
    let title: String
    let dotColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.mutedFg)
                .tracking(0.5)
        }
    }
}

// MARK: - Warm Card Container

struct WarmCard<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: Content

    init(cornerRadius: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .warmShadow()
    }
}

// MARK: - Form Components

struct FormHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
            }
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .warmShadowLg()
    }
}

struct FormTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.primaryTeal)
                    .frame(width: 20)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mutedFg)
                TextField(placeholder.isEmpty ? label : placeholder, text: $text)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.nearBlack)
                    .keyboardType(keyboardType)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.mutedBg.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct FormTextEditor: View {
    let label: String
    @Binding var text: String
    var icon: String? = nil
    var minHeight: CGFloat = 120

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.primaryTeal)
                    .frame(width: 20)
                    .padding(.top, 2)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mutedFg)
                TextEditor(text: $text)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.nearBlack)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: minHeight)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.mutedBg.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct FormSection<Content: View>: View {
    let title: String?
    let dotColor: Color
    @ViewBuilder let content: Content

    init(title: String? = nil, dotColor: Color = Color.primaryTeal, @ViewBuilder content: () -> Content) {
        self.title = title
        self.dotColor = dotColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                SectionLabel(title: title, dotColor: dotColor)
            }
            VStack(spacing: 12) {
                content
            }
            .padding(16)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .warmShadow()
        }
    }
}

struct FormColorPicker: View {
    @Binding var selection: Int
    let colors: [String]
    let names: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<colors.count, id: \.self) { i in
                Button {
                    selection = i
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            if selection == i {
                                Circle()
                                    .strokeBorder(Color(hex: colors[i]), lineWidth: 2)
                                    .frame(width: 44, height: 44)
                            }
                            Circle()
                                .fill(Color(hex: colors[i]))
                                .frame(width: 36, height: 36)
                            if selection == i {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 3)
                                    .frame(width: 36, height: 36)
                            }
                        }
                        Text(names[i])
                            .font(.system(size: 9))
                            .foregroundStyle(Color.mutedFg)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FormChipPicker<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let labels: (T) -> String
    let gradient: [Color]
    let icons: ((T) -> String)?

    init(selection: Binding<T>, options: [T], labels: @escaping (T) -> String,
         gradient: [Color], icons: ((T) -> String)? = nil) {
        self._selection = selection
        self.options = options
        self.labels = labels
        self.gradient = gradient
        self.icons = icons
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option
                Button {
                    selection = option
                } label: {
                    HStack(spacing: 5) {
                        if let icons = icons {
                            Image(systemName: icons(option))
                                .font(.system(size: 12))
                                .foregroundStyle(isSelected ? .white : Color.mutedFg)
                        }
                        Text(labels(option))
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? .white : Color.mutedFg)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background {
                        if isSelected {
                            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        } else {
                            Color.mutedBg
                        }
                    }
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
