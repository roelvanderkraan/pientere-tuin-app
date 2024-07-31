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
                Text("20")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("mm vandaag")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Text("8 mm verwacht op donderdag")
        }
        .task {
            Task.detached { @MainActor in
                await weatherData.dailyForecast(for: latestMeasurement)
            }
        }
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
