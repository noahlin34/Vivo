//
//  Medication.swift
//  Vivo
//

import Foundation
import SwiftData

@Model
final class Medication {
    var name: String = ""
    var dosage: String = ""
    var frequency: String = "Once daily"
    var scheduledTime: Date = Date()
    var colorIndex: Int = 0
    var notes: String = ""
    var takenDates: [Date] = []
    var createdAt: Date = Date()

    /// Number of doses required per day (0 = "As needed" — no target)
    var dosesRequired: Int {
        switch frequency {
        case "Twice daily":       return 2
        case "Three times daily": return 3
        case "As needed":         return 0
        default:                  return 1
        }
    }

    /// How many doses have been logged today
    var dosesTakenToday: Int {
        takenDates.filter { Calendar.current.isDateInToday($0) }.count
    }

    /// True only for scheduled meds where all required doses are logged
    var isTakenToday: Bool {
        dosesRequired > 0 && dosesTakenToday >= dosesRequired
    }

    init(name: String, dosage: String, frequency: String, scheduledTime: Date, colorIndex: Int = 0, notes: String = "") {
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.scheduledTime = scheduledTime
        self.colorIndex = colorIndex
        self.notes = notes
        self.createdAt = Date()
    }
}
