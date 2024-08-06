//
//  PrecipitationList.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 06/08/2024.
//

import SwiftUI

struct PrecipitationList: View {
    @EnvironmentObject private var weatherData: WeatherData

    var body: some View {
        List {
            if let forecasts = weatherData.dailyForecastData {
                    ForEach(forecasts, id: \.date) { forecast in
                        HStack {
                            Text(RelativeDateFormatter.relativeDateText(from: Date(), to: forecast.date) ?? "")
                                .frame(width: 100, alignment: .leading)
                            Image(systemName: forecast.symbolName)
                            Text("\(MeasurementFormatter.formatMeasurementToMM(measurement: forecast.precipitationAmount)) \(forecast.precipitation.description)")
                            Spacer()
                            Text("\(forecast.precipitationChance*100, specifier: "%.0f")%")
                        }
                }
            }
        }
        .navigationTitle("Neerslag in je tuin")
    }
}

//#Preview {
////    var weatherData = WeatherData.shared
////    PrecipitationList()
////        .environmentObject(weatherData)
//
//}
