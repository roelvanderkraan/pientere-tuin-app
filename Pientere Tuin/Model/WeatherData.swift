/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The data provider that loads weather forecast data from the WeatherKit service.
*/

import Foundation
import WeatherKit
import MapKit
import os

@MainActor
class WeatherData: ObservableObject {
    let logger = Logger(subsystem: "com.example.apple-samplecode.FlightPlanner.WeatherData", category: "Model")
    
    static let shared = WeatherData()
    
    @Published var dailyForecastData: Forecast<DayWeather>?
    @Published var attribution: WeatherAttribution?
    
    private let service = WeatherService.shared
    private var expirationDate: Date?
    
    
    @discardableResult
    func dailyForecast(for location: CLLocation) async -> Forecast<DayWeather>? {
        if let expirationDate = expirationDate, expirationDate > Date() {
            debugPrint("Weather not expired yet")
            return nil
        }
            let dayWeather = await Task.detached(priority: .userInitiated) {
                let forcast = try? await self.service.weather(
                    for: location,
                    including: .daily)
                return forcast
            }.value
            dailyForecastData = dayWeather
            expirationDate = dayWeather?.metadata.expirationDate
            debugPrint("Weather loaded. Expiration date: \(String(describing: expirationDate?.formatted()))")
            return dayWeather
    }
    
    func weatherAttribution() async {
        let attribution = await Task.detached(priority: .userInitiated) {
            let attribution = try? await self.service.attribution
            return attribution
        }.value
        self.attribution = attribution
    }
}
