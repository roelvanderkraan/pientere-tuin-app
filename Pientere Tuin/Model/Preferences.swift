//
//  Preferences.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 17/08/2023.
//

import SwiftUI

class Preferences: ObservableObject {
    static var shared = Preferences()

    @Published var chartScale: ChartScale = .week

    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notifications.enabled") }
    }
    /// Minimum days between notifications (cooldown). Options: 1, 3, 7
    @Published var notificationCooldownDays: Int {
        didSet { UserDefaults.standard.set(notificationCooldownDays, forKey: "notifications.cooldownDays") }
    }
    @Published var lastNotificationDate: Date? {
        didSet { UserDefaults.standard.set(lastNotificationDate, forKey: "notifications.lastSentDate") }
    }

    init() {
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notifications.enabled")
        let stored = UserDefaults.standard.integer(forKey: "notifications.cooldownDays")
        notificationCooldownDays = stored > 0 ? stored : 1  // default: daily
        lastNotificationDate = UserDefaults.standard.object(forKey: "notifications.lastSentDate") as? Date
    }
}
