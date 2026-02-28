//
//  SharedComponents.swift
//  Vivo
//

import SwiftUI

// MARK: - Design Tokens

extension Color {
    // Background and surface
    static let bg = Color(hex: "F6F2EC")          // warm cream
    static let cardBg = Color.white
    static let mutedBg = Color(hex: "E8E2D9")

    // Text
    static let nearBlack = Color(hex: "1A1612")
    static let mutedFg = Color(hex: "8C8279")

    // Primary
    static let primaryTeal = Color(hex: "0D7C66")

    // Gradient palette
    static let tealStart = Color(hex: "0D7C66")
    static let tealEnd = Color(hex: "059669")
    static let amberStart = Color(hex: "D97706")
    static let amberEnd = Color(hex: "F59E0B")
    static let cyanStart = Color(hex: "0891B2")
    static let cyanEnd = Color(hex: "06B6D4")
    static let purpleStart = Color(hex: "7C3AED")
    static let purpleEnd = Color(hex: "A78BFA")

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

// MARK: - Shadow Helpers

extension View {
    func warmShadow() -> some View {
        shadow(color: Color(hex: "1A1612").opacity(0.06), radius: 8, x: 0, y: 2)
    }
    func warmShadowLg() -> some View {
        shadow(color: Color(hex: "1A1612").opacity(0.08), radius: 16, x: 0, y: 4)
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
                }

                Spacer()

                // Time badge
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
            Text(initial)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    LinearGradient(colors: style.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
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
