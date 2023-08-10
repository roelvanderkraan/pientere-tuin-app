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

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MeasurementProjection.measuredAt, ascending: true)],
        animation: .default)
    private var measurements: FetchedResults<MeasurementProjection>
    
    let client: Client
    
    var body: some View {
        NavigationView {
            List {
                ForEach (measurements) { measurement in
                    VStack {
                        Text("\(measurement.moisturePercentage)")
                        Text("\(measurement.temperatureCelcius)")
                        Text("\(measurement.measuredAt ?? Date())")
                    }
                }
            }
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Load") {
                        Task {
                            try? await updateTuinData()
                        }
                    }
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
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
        let response = try await client.get_mijn_pientere_tuin_measurements(
            .init(
                headers: Operations.get_mijn_pientere_tuin_measurements.Input.Headers(wecity_api_key: "ee3f7468-11fb-43b6-b870-49f9435524c1")
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
        case .tooManyRequests(_):
            debugPrint("Too many requests")
        }
    }
    
    func writeToCoreData(apiData: [Components.Schemas.MeasurementProjection]?) {
        if let apiData = apiData {
            for item in apiData {
                let dataItem = MeasurementProjection(context: viewContext)
//                dataItem. = item.
                dataItem.measuredAt = item.measuredAt
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
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
