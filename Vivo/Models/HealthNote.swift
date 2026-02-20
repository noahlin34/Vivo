//
//  HealthNote.swift
//  Vivo
//

import Foundation
import SwiftData

@Model
final class HealthNote {
    var title: String = ""
    var content: String = ""
    var category: String = "General"
    var createdAt: Date = Date()

    init(title: String, content: String, category: String = "General") {
        self.title = title
        self.content = content
        self.category = category
        self.createdAt = Date()
    }
}
