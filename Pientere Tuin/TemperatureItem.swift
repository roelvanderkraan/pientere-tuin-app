//
//  TemperatureItem.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 12/08/2023.
//

import SwiftUI
import Charts

struct TemperatureItem: View {
    @FetchRequest var measurements: FetchedResults<MeasurementProjection>
        
    @Environment(\.managedObjectContext) private var viewContext

    
    var body: some View {
        VStack {
            if let latestMeasurement = measurements.first {
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(Image(systemName: "thermometer.medium")) Soil temperature")
                            .font(.system(.body, design: .default, weight: .medium))
                            .foregroundColor(.green)
                        Spacer()
                        Text("\(latestMeasurement.measuredAt ?? Date(), formatter: itemFormatter)")
                            .foregroundColor(.secondary)
                    }
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(latestMeasurement.temperatureCelcius, specifier: "%.0f")")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        Text("°C")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                
            }
            Chart {
                ForEach (measurements) { measurement in
                    if measurement.temperatureCelcius != 0.0 {
                        LineMark(
                            x: .value("Month", measurement.measuredAt ?? Date()),
                            y: .value("Temperature", measurement.temperatureCelcius)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.blue, .yellow, .red],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .alignsMarkStylesWithPlotArea()
                    }
                }
            }
            .chartForegroundStyleScale([
                "Temperature": .green
            ])
            .chartLegend(.hidden)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 8))
            .chartYAxisLabel("°C")
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

struct TemperatureItem_Previews: PreviewProvider {
    static var previews: some View {
        HumidityItem(
            measurements: FetchRequest<MeasurementProjection>(
                sortDescriptors: [NSSortDescriptor(keyPath: \MeasurementProjection.measuredAt, ascending: false)],
                predicate: .filter(key: "measuredAt", date: Date(), scale: .month)
            )
        )
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
