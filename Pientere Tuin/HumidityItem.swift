//
//  HumidityItem.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 12/08/2023.
//

import SwiftUI
import Charts

struct HumidityItem: View {
    @FetchRequest var measurements: FetchedResults<MeasurementProjection>
        
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack {
            if let latestMeasurement = measurements.first {
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(Image(systemName: "humidity")) Soil humidity")
                            .font(.system(.body, design: .default, weight: .medium))
                            .foregroundColor(.blue)
                        Spacer()
                        Text("\(latestMeasurement.measuredAt ?? Date(), formatter: itemFormatter)")
                            .foregroundColor(.secondary)
                    }
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(latestMeasurement.moisturePercentage * 100, specifier: "%.1f")")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        Text("%")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
            Chart {
                ForEach (measurements) { measurement in
                    LineMark(
                        x: .value("Hour", measurement.measuredAt ?? Date(), unit: .hour),
                        y: .value("Moisture", measurement.moisturePercentage * 100)
                        
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.yellow, .green, .blue],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .alignsMarkStylesWithPlotArea()
                }
            }
            .chartForegroundStyleScale([
                "Moisture": .blue
            ])
            .chartLegend(.hidden)
            .padding([.trailing], 8)
            .chartYAxisLabel("%")
        }
        .padding([.bottom, .top], 8)
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

struct HumidityItem_Previews: PreviewProvider {
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
