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
    var date: Date = Date()
    var time: String = ""
    var location: String = ""
    var notes: String = ""
    var createdAt: Date = Date()

    init(title: String, doctorName: String, date: Date, time: String = "", location: String = "", notes: String = "") {
        self.title = title
        self.doctorName = doctorName
        self.date = date
        self.time = time
        self.location = location
        self.notes = notes
        self.createdAt = Date()
    }
}
