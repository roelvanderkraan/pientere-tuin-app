//
//  MeasurementList.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 10/08/2023.
//

import SwiftUI

struct MeasurementList: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MeasurementProjection.measuredAt, ascending: false)],
        animation: .default)
    private var measurements: FetchedResults<MeasurementProjection>
    
    var body: some View {
        List {
            ForEach (measurements) { measurement in
                VStack(alignment: .leading) {
                    Text("\(Image(systemName: "humidity")) \(measurement.moisturePercentage * 100.0, specifier: "%.1f")%")
                        .font(.system(size: 20.0, weight: .bold, design: .rounded))
                    Text("\(Image(systemName: "thermometer.medium")) \(measurement.temperatureCelcius, specifier: "%.1f")°")
                        .font(.system(size: 20.0, weight: .bold, design: .rounded))
                    // Text("\(measurement.apiUUID ?? "")")
                    Text("\(measurement.measuredAt ?? Date(), formatter: itemFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Measurements")
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

struct MeasurementList_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementList().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
