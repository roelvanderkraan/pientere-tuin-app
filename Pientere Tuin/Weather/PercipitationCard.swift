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
            HStack(alignment: .center) {
                Text("\(Image(systemName: "umbrella"))")
                Text("Neerslag in je tuin")
                Spacer()
                if let attribution = weatherData.attribution {
                    AsyncImage(url: attribution.combinedMarkLightURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 40, height: 8)
                }
            }
            .font(.system(.body, design: .default, weight: .medium))
            .foregroundColor(.purple)
            .padding([.bottom], 1)
            
            HStack(alignment: .firstTextBaseline) {
                if let rainToday = todayPercipitation {
                    weatherIcon
                    Text(formatMeasurement(measurement: rainToday))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .contentTransition(.numericText())
                    Text("VANDAAG")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            Text(futurePercipitation)
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
            // Remove today
            let futureForecasts = dailyForecast.dropFirst()
            let firstDayWithRain = futureForecasts.first { day in
                day.precipitationAmount.value >= 1
            }
            if let rainyDay = firstDayWithRain {
                return "\(relativeDateString(date: rainyDay.date)) \(formatMeasurement(measurement: rainyDay.precipitationAmount)) \(rainyDay.precipitation.description) verwacht."
            }
        }
        return "De komende 10 dagen geen neerslag verwacht."
    }
    
    var weatherIcon: some View {
        if let dailyForecast = weatherData.dailyForecastData, let systemName = dailyForecast.first?.symbolName {
            Text(Image(systemName: systemName))
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
        } else {
            Text("\(Image(systemName: "cloud.rain"))")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
        }
    }
    
    func formatMeasurement(measurement: Measurement<UnitLength>) -> String {
        let millimeters = measurement.converted(to: .millimeters)
        let roundedStyle = FloatingPointFormatStyle<Double>(locale: .autoupdatingCurrent)
            .rounded(rule: .toNearestOrAwayFromZero, increment: 1)
        return millimeters.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: roundedStyle))
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
