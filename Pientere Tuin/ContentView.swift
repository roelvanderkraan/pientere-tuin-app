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
    
    @State var chartScale: ChartScale = .month
    @State var isEditingGarden: Bool = false
    @State var isAddingGarden: Bool = false
    @ObservedObject var garden: Garden
    var apiTimer: ApiTimer
    
    var body: some View {
        NavigationView {
            List {
                Picker("Chart scale", selection: $chartScale) {
                    Text("D").tag(ChartScale.day)
                    Text("W").tag(ChartScale.week)
                    Text("M").tag(ChartScale.month)
                    Text("All").tag(ChartScale.all)
                }
                .pickerStyle(.segmented)
                Section {
                    HumidityItem(
                        measurements: FetchRequest<MeasurementProjection>(
                            sortDescriptors: [NSSortDescriptor(keyPath: \MeasurementProjection.measuredAt, ascending: false)],
                            predicate: .filter(key: "measuredAt", date: Date(), scale: chartScale)),
                        scale: $chartScale
                    )
                    .environment(\.managedObjectContext, viewContext)
                }
                Section {
                    TemperatureItem(
                        measurements: FetchRequest<MeasurementProjection>(
                            sortDescriptors: [NSSortDescriptor(keyPath: \MeasurementProjection.measuredAt, ascending: false)],
                            predicate: .filter(key: "measuredAt", date: Date(), scale: chartScale)),
                        scale: $chartScale)
                    .environment(\.managedObjectContext, viewContext)
                }
                Section {
                    NavigationLink {
                        MeasurementList()
                            .environment(\.managedObjectContext, viewContext)
                    } label: {
                        Text("All measurements")
                    }
                    Button("Refresh all measurements") {
                        Task {
                            try? await apiHandler.updateTuinData(context: viewContext, loadAll: true, garden: garden)
                        }
                    }
                }
            }
            .navigationTitle(garden.name ?? "Pientere Tuin")
            .toolbar {
                ToolbarItem {
                    Button {
                        isEditingGarden.toggle()
                    } label: {
                        Label("Edit garden", systemImage: "gear")
                    }

                }
            }
            .sheet(isPresented: $isEditingGarden) {
                GardenEdit(garden: garden, isPresented: $isEditingGarden)
            }
            .sheet(isPresented: $isAddingGarden) {
                Task {
                    try? await apiHandler.updateTuinData(context: viewContext, loadAll: true, garden: garden)
                }
            } content: {
                GardenNew(garden: garden, isPresented: $isAddingGarden, apiHandler: apiHandler)
                    .interactiveDismissDisabled()
            }

        }
        .refreshable {
            if apiTimer.isParseAllowed() {
                apiTimer.lastParseDate = Date()
                try? await apiHandler.updateTuinData(context: viewContext, garden: garden)
            }
        }
        .onAppear {
            if garden.apiKey == nil {
                isAddingGarden = true
            }
        }
    }
    
    init(garden: Garden, apiTimer: ApiTimer) {
        self.apiHandler = ApiHandler()
        self.apiTimer = apiTimer
        self.garden = garden
    }
    
    private func getMapRect() -> MKCoordinateRegion? {
        if let latestMeasurement = measurements.first {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: CLLocationDegrees(latestMeasurement.latitude), longitude: CLLocationDegrees(latestMeasurement.longitude)),
                latitudinalMeters: 750,
                longitudinalMeters: 750
            )
            return region
        }
        return nil
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
        let context = PersistenceController.preview.container.viewContext
        let garden = GardenStore.testGarden(in: context)
        ContentView(garden: garden, apiTimer: ApiTimer())
            .environment(\.managedObjectContext, context)
    }
}
