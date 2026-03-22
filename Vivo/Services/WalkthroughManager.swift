//
//  WalkthroughManager.swift
//  Vivo
//

import SwiftUI

enum WalkthroughStep {
    case tapMedsTab
    case tapAddButton
    case addingMedication
    case complete
}

@Observable
final class WalkthroughManager {
    var isActive: Bool = false
    var currentStep: WalkthroughStep = .tapMedsTab
    var medsTabFrame: CGRect = .zero
    var addButtonFrame: CGRect = .zero

    func advance() {
        guard isActive else { return }
        switch currentStep {
        case .tapMedsTab:      currentStep = .tapAddButton
        case .tapAddButton:    currentStep = .addingMedication
        case .addingMedication: currentStep = .complete
        case .complete:        break
        }
    }

    func finish() {
        isActive = false
    }
}
