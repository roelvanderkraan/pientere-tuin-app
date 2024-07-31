//
//  TemperatureCard.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 16/08/2023.
//

import SwiftUI

struct TemperatureCard: View {
    var latestMeasurement: MeasurementProjection
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(Image(systemName: "thermometer.medium")) Temperatuur bodem")
                    .font(.system(.body, design: .default, weight: .medium))
                    .foregroundColor(.green)
                Spacer()
                Text("\(latestMeasurement.measuredAt ?? Date(), formatter: Formatters.itemFormatter)")
                    .foregroundColor(.secondary)
            }
            .padding([.bottom], 1)
            if let temperature = latestMeasurement.temperatureCelcius {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(temperature.floatValue, specifier: "%.0f")")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("°C")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct TemperatureCard_Previews: PreviewProvider {
    static var previews: some View {
        let context =  PersistenceController.preview.container.viewContext

        TemperatureCard(latestMeasurement: MeasurementStore.addTestMeasurement(to: context))
    }
}
