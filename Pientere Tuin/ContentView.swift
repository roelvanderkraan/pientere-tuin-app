//
//  ContentView.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 09/08/2023.
//

import SwiftUI
import CoreData
import OpenAPIRuntime
import OpenAPIURLSession
import Charts
import MapKit

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let apiHandler: ApiHandler
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MeasurementProjection.measuredAt, ascending: false)],
        animation: .default)
    private var measurements: FetchedResults<MeasurementProjection>
    
    var body: some View {
        NavigationView {
            List {
                Section {
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
                                x: .value("Month", measurement.measuredAt ?? Date()),
                                y: .value("Moisture", measurement.moisturePercentage * 100)
                                
                            )
                            .foregroundStyle(by: .value("Type", "Moisture"))
                        }
                    }
                    .chartForegroundStyleScale([
                        "Moisture": .blue
                    ])
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 8))
                }
                Section {
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
                                Text("\(latestMeasurement.temperatureCelcius, specifier: "%.1f")")
                                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                                //.font(.system(size: 30.0, weight: .bold, design: .rounded))
                                Text("°C")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                    }
                    Chart {
                        ForEach (measurements) { measurement in
                            LineMark(
                                x: .value("Month", measurement.measuredAt ?? Date()),
                                y: .value("Temperature", measurement.temperatureCelcius)
                            )
                            .foregroundStyle(by: .value("Type", "Temperature"))
                        }
                    }
                    .chartForegroundStyleScale([
                        "Temperature": .green
                    ])
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 8))
                }
                Section {
                    NavigationLink {
                        MeasurementList()
                            .environment(\.managedObjectContext, viewContext)
                    } label: {
                        Text("All measurements")
                    }
                }
            }
            .navigationTitle("Pientere Tuin")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            try? await apiHandler.updateTuinData(context: viewContext)
                        }
                    } label: {
                        Label("Refresh alles", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        }
        .refreshable {
            Task {
                try? await apiHandler.updateTuinData(context: viewContext)
            }
        }
    }
    
    init() {
        self.apiHandler = ApiHandler()
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
