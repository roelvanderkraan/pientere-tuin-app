//
//  PrecipitationList.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 06/08/2024.
//

import SwiftUI
import SimpleAnalytics

struct PrecipitationList: View {
    @EnvironmentObject private var weatherData: WeatherData

    var body: some View {
        List {
            if let forecasts = weatherData.dailyForecastData {
                Section {
                    ForEach(forecasts, id: \.date) { forecast in
                        HStack {
                            Text(RelativeDateFormatter.relativeDateText(from: Date(), to: forecast.date, dayType: .short) ?? "")
                                .frame(width: 80, alignment: .leading)
                                .fontWeight(.medium)
                            VStack(alignment: .center) {
                                Image(systemName: forecast.symbolName)
                                    .frame(width: 30, alignment: .center)
                                if forecast.precipitationAmount.value >= 1 {
                                    Text("\(getPrecipitationChangeString(chance: forecast.precipitationChance))")
                                        .foregroundStyle(.blue)
                                        .fontDesign(.rounded)
                                        .font(.caption)
                                }
                            }
                            .padding(.trailing, 8)
                            if forecast.precipitationAmount.value >= 1 {
                                HStack {
                                    Text("\(MeasurementFormatter.formatMeasurementToMM(measurement: forecast.precipitationAmount))")
                                        .fontDesign(.rounded)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.blue)
                                    Text("\(forecast.precipitation.description)")
                                }
                            }
                        }
                    }
                } footer: {
                    WeatherAttributionView()
                        .environmentObject(weatherData)
                }
            }
        }
        .navigationTitle("Neerslag in je tuin")
        .onAppear {
            SimpleAnalytics.shared.track(path: ["precipitationList"])
        }
    }
    
    func getPrecipitationChangeString(chance: Double) -> String {
        let roundedChance = (round(chance / 0.05) * 0.05)
        return roundedChance.formatted(.percent)
    }
}

#Preview {
    PrecipitationList()
        .environmentObject(WeatherData.shared)

}
