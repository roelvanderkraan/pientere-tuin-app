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
    
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.measuredAt, order: .reverse)],
        animation: .default)
    private var measurements: FetchedResults<MeasurementProjection>
    
    @State var chartScale: ChartScale = .month
    @State var isEditingGarden: Bool = false
    @State var isAddingGarden: Bool = false
    @ObservedObject var garden: Garden
    var apiTimer: ApiTimer
    
    var body: some View {
        NavigationSplitView {
            List {
                Section {
                    if let lastMeasurement = measurements.first {
                        NavigationLink {
                            HumidityDetails()
                                .environment(\.managedObjectContext, viewContext)
                        } label: {
                            HumidityCard(latestMeasurement: lastMeasurement)
                        }
                    }
                }
                Section {
                    if let lastMeasurement = measurements.first {
                        NavigationLink {
                            TemperatureDetails()
                                .environment(\.managedObjectContext, viewContext)
                        } label: {
                            TemperatureCard(latestMeasurement: lastMeasurement)
                        }
                        
                    }
                }
                Section {
                    if let lastMeasurement = measurements.first {
                        NavigationLink {
                            GardenDetails(latestMeasurement: lastMeasurement)
                        } label: {
                            Text("Garden details")
                        }
                    }
                }
            }
            .navigationTitle("Pientere Tuin")
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
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $isAddingGarden) {
                Task {
                    try? await ApiHandler.shared.updateTuinData(context: viewContext, loadAll: true, garden: garden)
                }
            } content: {
                GardenNew(garden: garden, isPresented: $isAddingGarden)
                    .environment(\.managedObjectContext, viewContext)
                    .interactiveDismissDisabled()
            }
            .refreshable {
                if apiTimer.isParseAllowed() {
                    apiTimer.lastParseDate = Date()
                    try? await ApiHandler.shared.updateTuinData(context: viewContext, garden: garden)
                }
            }

        } detail: {
            HumidityDetails()
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            if garden.apiKey == nil {
                isAddingGarden = true
            }
        }
    }
    
    init(garden: Garden, apiTimer: ApiTimer) {
        self.apiTimer = apiTimer
        self.garden = garden
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
