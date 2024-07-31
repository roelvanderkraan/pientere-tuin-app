//
//  PercipitationCard.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 31/07/2024.
//

import SwiftUI
import WeatherKit

struct PercipitationCard: View {
    @ObservedObject var latestMeasurement: MeasurementProjection
    @EnvironmentObject private var weatherData: WeatherData

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(Image(systemName: "cloud.rain")) Neerslag")
                    .font(.system(.body, design: .default, weight: .medium))
                    .foregroundColor(.purple)
            }
            .padding([.bottom], 1)
            HStack(alignment: .firstTextBaseline) {
                if let rainToday = todayPercipitation {
                    Text(formatMeasurement(measurement: rainToday))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("VANDAAG")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            Text(futurePercipitation)
        }
        .task {
            Task.detached { @MainActor in
                await weatherData.dailyForecast(for: latestMeasurement)
            }
        }
    }
    
    var todayPercipitation: Measurement<UnitLength>? {
        if let dailyForecast = weatherData.dailyForecastData {
            return dailyForecast.first?.precipitationAmount as? Measurement<UnitLength>
        }
        return nil
    }
    
    var futurePercipitation: String {
        if let dailyForecast = weatherData.dailyForecastData {
            let firstDayWithRain = dailyForecast.first { day in
                day.precipitationAmount.value > 0
            }
            if let rainyDay = firstDayWithRain {
                return "\(rainyDay.precipitationAmount.formatted()) \(rainyDay.precipitation.description) verwacht op \(relativeDateString(date: rainyDay.date))"
            }
        }
        return "Geen neerslag verwacht"
    }
    
    func formatMeasurement(measurement: Measurement<UnitLength>) -> String {
        let millimeters = measurement.converted(to: .millimeters)
        return millimeters.formatted()
    }
    
    func relativeDateString(date: Date) -> String {
        return RelativeDateFormatter.relativeDateText(from: Date(), to: date) ?? ""
    }
}


struct PercipitationCard_Previews: PreviewProvider {
    static var previews: some View {
        let context =  PersistenceController.preview.container.viewContext
        let weatherData = WeatherData.shared
        PercipitationCard(latestMeasurement: MeasurementStore.addTestMeasurement(to: context))
            .environmentObject(weatherData)

    }
}
