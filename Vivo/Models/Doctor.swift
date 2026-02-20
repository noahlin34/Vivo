//
//  Doctor.swift
//  Vivo
//

import Foundation
import SwiftData

@Model
final class Doctor {
    var name: String = ""
    var specialty: String = ""
    var phone: String = ""
    var email: String = ""
    var address: String = ""
    var colorIndex: Int = 0
    var createdAt: Date = Date()

    init(name: String, specialty: String, phone: String = "", email: String = "", address: String = "", colorIndex: Int = 0) {
        self.name = name
        self.specialty = specialty
        self.phone = phone
        self.email = email
        self.address = address
        self.colorIndex = colorIndex
        self.createdAt = Date()
    }
}
