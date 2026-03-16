//
//  VitalRecord.swift
//  Vivo
//

import Foundation
import SwiftUI
import SwiftData

@Model
final class VitalRecord {
    var type: String = ""
    var value: Double = 0
    var secondaryValue: Double? = nil
    var unit: String = ""
    var notes: String = ""
    var source: String = "manual"
    var recordedAt: Date = Date()
    var createdAt: Date = Date()

    init(type: String, value: Double, secondaryValue: Double? = nil, unit: String, notes: String = "", source: String = "manual", recordedAt: Date = Date()) {
        self.type = type
        self.value = value
        self.secondaryValue = secondaryValue
        self.unit = unit
        self.notes = notes
        self.source = source
        self.recordedAt = recordedAt
        self.createdAt = Date()
    }
}

// MARK: - Vital Type Helper

enum VitalType: String, CaseIterable {
    case bloodPressure = "Blood Pressure"
    case weight = "Weight"
    case heartRate = "Heart Rate"
    case bloodSugar = "Blood Sugar"

    var icon: String {
        switch self {
        case .bloodPressure: return "heart.fill"
        case .weight:        return "scalemass.fill"
        case .heartRate:     return "waveform.path.ecg"
        case .bloodSugar:    return "drop.fill"
        }
    }

    var unit: String {
        switch self {
        case .bloodPressure: return "mmHg"
        case .weight:        return "lbs"
        case .heartRate:     return "bpm"
        case .bloodSugar:    return "mg/dL"
        }
    }

    var hasDualValue: Bool {
        self == .bloodPressure
    }

    func formatValue(_ value: Double, secondary: Double? = nil) -> String {
        switch self {
        case .bloodPressure:
            let sys = Int(value)
            let dia = Int(secondary ?? 0)
            return "\(sys)/\(dia)"
        case .weight:
            return value.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(value))"
                : String(format: "%.1f", value)
        case .heartRate:
            return "\(Int(value))"
        case .bloodSugar:
            return "\(Int(value))"
        }
    }

    var color: Color {
        switch self {
        case .bloodPressure: return Color(hex: "E11D48")
        case .weight:        return Color(hex: "0891B2")
        case .heartRate:     return Color(hex: "E11D48")
        case .bloodSugar:    return Color(hex: "7C3AED")
        }
    }

    var gradient: [Color] {
        switch self {
        case .bloodPressure: return [Color(hex: "E11D48"), Color(hex: "F43F5E")]
        case .weight:        return [Color(hex: "0891B2"), Color(hex: "06B6D4")]
        case .heartRate:     return [Color(hex: "E11D48"), Color(hex: "F43F5E")]
        case .bloodSugar:    return [Color(hex: "7C3AED"), Color(hex: "A78BFA")]
        }
    }
}
