//
//  NotificationHandler.swift
//  Pientere Tuin
//

import UserNotifications
import CoreData

class NotificationHandler {
    static let shared = NotificationHandler()

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func evaluateAndNotify(context: NSManagedObjectContext) async {
        let prefs = Preferences.shared
        guard prefs.notificationsEnabled else { return }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
           || settings.authorizationStatus == .provisional else { return }

        // Cooldown check
        if let lastSent = prefs.lastNotificationDate {
            let cooldown = TimeInterval(prefs.notificationCooldownDays * 24 * 60 * 60)
            guard Date().timeIntervalSince(lastSent) >= cooldown else { return }
        }

        guard let measurement = MeasurementStore.getLastMeasurement(in: context) else { return }
        let state = measurement.humidityState
        guard state == .stress || state == .tooDry else { return }

        // WeatherKit rain suppression (cached data; nil = skip suppression)
        let forecast = await MainActor.run { WeatherData.shared.dailyForecastData }
        if let forecast {
            let today = Calendar.current.startOfDay(for: Date())
            if let todayForecast = forecast.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }),
               todayForecast.precipitationChance > 0.3 { return }
        }

        await fire(for: state)
        await MainActor.run { prefs.lastNotificationDate = Date() }
    }

    private func fire(for state: HumidityState) async {
        let content = UNMutableNotificationContent()
        content.sound = .default
        switch state {
        case .stress:
            content.title = "Je tuin heeft water nodig"
            content.body  = "De bodem begint droog te worden. Overweeg je tuin water te geven."
        case .tooDry:
            content.title = "Je tuin is te droog!"
            content.body  = "De bodemvochtigheid is te laag. Geef je tuin water."
        default: return
        }
        let request = UNNotificationRequest(
            identifier: "studio.skipper.Pientere-Tuin.wateringReminder",
            content: content, trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
