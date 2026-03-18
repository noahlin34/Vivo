//
//  NotificationService.swift
//  Vivo
//

import UserNotifications

enum NotificationService {
    static func ensureAuthorizedThenSchedule(_ block: @escaping (UNUserNotificationCenter) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                block(center)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    if granted { block(center) }
                }
            case .denied:
                break
            @unknown default:
                break
            }
        }
    }
}
