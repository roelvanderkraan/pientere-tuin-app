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

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MeasurementProjection.measuredAt, ascending: false)],
        animation: .default)
    private var measurements: FetchedResults<MeasurementProjection>
    
    let client: Client
    
    var body: some View {
        NavigationView {
            List {
                Section("Soil moisture") {
                    if let latestMeasurement = measurements.first {
                        HStack {
                            Text("\(Image(systemName: "humidity")) \(latestMeasurement.moisturePercentage * 100, specifier: "%.1f")%")
                                .font(.system(size: 30.0, weight: .bold, design: .rounded))
                            Spacer()
                            Text("\(latestMeasurement.measuredAt ?? Date(), formatter: itemFormatter)")
                                .foregroundColor(.secondary)
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
                Section("Soil temperature") {
                    if let latestMeasurement = measurements.first {
                        HStack {
                            Text("\(Image(systemName: "thermometer.medium")) \(latestMeasurement.temperatureCelcius, specifier: "%.1f")°")
                                .font(.system(size: 30.0, weight: .bold, design: .rounded))
                            Spacer()
                            Text("\(latestMeasurement.measuredAt ?? Date(), formatter: itemFormatter)")
                                .foregroundColor(.secondary)
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
                        "Temperature": .black
                    ])
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 8))
                }
                Section {
                    NavigationLink {
                        MeasurementList()
                    } label: {
                        Text("All measurements")
                    }

                }
            }
            .navigationTitle("Pientere Tuin")
            .toolbar {
#if os(iOS)
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Load") {
                        Task {
                            try? await updateTuinData()
                        }
                    }
                }
#endif
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
            }
//            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    init() {
        self.client = Client(
            serverURL: try! Servers.server1(),
            transport: URLSessionTransport()
        )
    }
    
    func updateTuinData() async throws {
        let response = try await client.mijnPientereTuin(
            .init(
                headers: Operations.mijnPientereTuin.Input.Headers(wecity_api_key: "ee3f7468-11fb-43b6-b870-49f9435524c1")
            )
        )
        
        switch response {
        case let .ok(okResponse):
            debugPrint("OK!")
            debugPrint(okResponse.body)
            switch okResponse.body {
            case .json(let json):
                writeToCoreData(apiData: json.content)
            }
        case .undocumented(statusCode: let statusCode, _):
            debugPrint("Error getting data from server, status: \(statusCode)")
        }
    }
    
    func writeToCoreData(apiData: [Components.Schemas.MeasurementProjection]?) {
        if let apiData = apiData {
            for item in apiData {
                let dataItem = MeasurementProjection(context: viewContext)
//                dataItem. = item.
                dataItem.measuredAt = item.measuredAt
                dataItem.apiUUID = item.id 
                if let moisture = item.moisturePercentage {
                    dataItem.moisturePercentage = moisture
                }
                if let temperature = item.temperatureCelsius {
                    dataItem.temperatureCelcius = Float(temperature)
                }
            }
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
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
