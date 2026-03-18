//
//  NotificationStatusMonitor.swift
//  Vivo
//

import UserNotifications

@Observable
final class NotificationStatusMonitor {
    var isAuthorized: Bool = true
    var isDenied: Bool = false

    func refresh() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
                self.isDenied = settings.authorizationStatus == .denied
            }
        }
    }
}
