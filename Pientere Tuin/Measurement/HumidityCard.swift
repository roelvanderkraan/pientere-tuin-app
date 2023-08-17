//
//  TemperatureCard.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 16/08/2023.
//

import SwiftUI

struct HumidityCard: View {
    @ObservedObject var latestMeasurement: MeasurementProjection
    var body: some View {
        let humidityState = latestMeasurement.humidityState
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(Image(systemName: "humidity")) Soil humidity")
                    .font(.system(.body, design: .default, weight: .medium))
                    .foregroundColor(.blue)
                Spacer()
                Text("\(latestMeasurement.measuredAt ?? Date(), formatter: Formatters.itemFormatter)")
                    .foregroundColor(.secondary)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("\(latestMeasurement.moisturePercentage * 100, specifier: "%.1f")")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("%")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
            }
            HumidityStateText(humidityState: latestMeasurement.humidityState)
        }
    }
}

struct HumidityCard_Previews: PreviewProvider {
    static var previews: some View {
        let context =  PersistenceController.preview.container.viewContext

        HumidityCard(latestMeasurement: MeasurementStore.addTestMeasurement(to: context))
    }
}