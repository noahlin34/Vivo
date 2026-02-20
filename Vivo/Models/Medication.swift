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
    var createdAt: Date = Date()

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
