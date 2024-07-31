/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The data provider that loads weather forecast data from the WeatherKit service.
*/

import Foundation
import WeatherKit
import os

@MainActor
class WeatherData: ObservableObject {
    let logger = Logger(subsystem: "com.example.apple-samplecode.FlightPlanner.WeatherData", category: "Model")
    
    static let shared = WeatherData()
    
    private let service = WeatherService.shared
    
    
    @discardableResult
    func dailyForecast(for measurement: MeasurementProjection) async -> Forecast<DayWeather>? {
        let dayWeather = await Task.detached(priority: .userInitiated) {
            let forcast = try? await self.service.weather(
                for: measurement.location(),
                including: .daily)
            return forcast
        }.value
        return dayWeather
    }
}
