//
//  Appointment.swift
//  Vivo
//

import Foundation
import SwiftData

@Model
final class Appointment {
    var title: String = ""
    var doctorName: String = ""
    @Relationship(deleteRule: .nullify) var doctor: Doctor? = nil
    var date: Date = Date()

    var displayDoctorName: String { doctor?.name ?? doctorName }
    var location: String = ""
    var notes: String = ""
    var reminderOption: String = "1_day_1_hour"
    var createdAt: Date = Date()

    init(title: String, doctorName: String, date: Date, location: String = "", notes: String = "") {
        self.title = title
        self.doctorName = doctorName
        self.date = date
        self.location = location
        self.notes = notes
        self.createdAt = Date()
    }
}
