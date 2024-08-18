//
//  ContentView.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 09/08/2023.
//

import SwiftUI
import CoreData
import Charts
import MapKit
import SimpleAnalytics
import CachedAsyncImage

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    let persistenceController = PersistenceController.shared
    
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.measuredAt, order: .reverse)],
        animation: .default)
    private var measurements: FetchedResults<MeasurementProjection>
    
    @State var chartScale: ChartScale = .month
    @State var isEditingGarden: Bool = false
    @State var isAddingGarden: Bool = false
    @State var isError: Bool = false
    @State var errorMessage: String?
    @StateObject private var weatherData = WeatherData.shared
    @ObservedObject var garden: Garden
    var apiTimer: ApiTimer
    
    var body: some View {
        NavigationView {
            List {
                if let lastMeasurement = measurements.first {
                    Section {
                            NavigationLink {
                                HumidityDetails()
                                    .environment(\.managedObjectContext, viewContext)
                            } label: {
                                HumidityCard(latestMeasurement: lastMeasurement)
                            }
                    }
                    Section {
                            NavigationLink {
                                TemperatureDetails()
                                    .environment(\.managedObjectContext, viewContext)
                            } label: {
                                TemperatureCard(latestMeasurement: lastMeasurement)
                            }
                    }
                    Section {
                        NavigationLink {
                           PrecipitationList()
                                .environmentObject(weatherData)
                        } label: {
                            PercipitationCard(latestMeasurement: lastMeasurement)
                                .environmentObject(weatherData)
                        }
                    } footer: {
                        WeatherAttributionView()
                            .environmentObject(weatherData)
                    }
                    Section {
                            NavigationLink {
                                GardenDetails(latestMeasurement: lastMeasurement)
                            } label: {
                                Text("Tuindetails")
                            }
                    }
                } else {
                    Text("Geen metingen gevonden")
                }
            }
            .navigationTitle("Pientere Tuin")
            .toolbar {
                ToolbarItem {
                    Button {
                        isEditingGarden.toggle()
                    } label: {
                        Label("Instellingen", systemImage: "gear")
                    }

                }
            }
            .sheet(isPresented: $isEditingGarden) {
                Settings(garden: garden, isPresented: $isEditingGarden)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $isAddingGarden) {
                Task {
                    try? await ApiHandler.shared.updateTuinData(context: viewContext, loadAll: true, garden: garden)
                }
            } content: {
                LaunchView(garden: garden, isPresented: $isAddingGarden)
                    .environment(\.managedObjectContext, viewContext)
                    .interactiveDismissDisabled()
            }
            .alert(errorMessage ?? "Fout bij het ophalen van de data, probeer het later nog eens.", isPresented: $isError) {
                Button("OK") {
                    isError = false
                }
            }
            .refreshable {
                await refreshData()
                SimpleAnalytics.shared.track(event: "refresh", path: ["contentView"])
            }

        }
        .onAppear {
            if garden.apiKey == nil {
                isAddingGarden = true
            }
            SimpleAnalytics.shared.track(path: ["contentView"])
        }
        .task {
            Task.detached { @MainActor in
                if let lastMeasurement = MeasurementStore.getLastMeasurement(in: persistenceController.container.newBackgroundContext()) {
                    await weatherData.dailyForecast(for: lastMeasurement.location())
                }
            }
            Task.detached { @MainActor in
                await weatherData.weatherAttribution()
            }
        }
    }
    
    init(garden: Garden, apiTimer: ApiTimer) {
        self.apiTimer = apiTimer
        self.garden = garden
    }
    
    private func refreshData() async {
        if apiTimer.isParseAllowed() {
            apiTimer.lastParseDate = Date()
            do {
                try await ApiHandler.shared.updateTuinData(context: viewContext, garden: garden)
            } catch APIError.notAuthorized {
                errorMessage = "Geen toegang"   
                isError = true
            } catch {
                return
            }
        }
        Task.detached { @MainActor in
            if let lastMeasurement = MeasurementStore.getLastMeasurement(in: persistenceController.container.newBackgroundContext()) {
                await weatherData.dailyForecast(for: lastMeasurement.location())
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
        let context = PersistenceController.preview.container.viewContext
        let garden = GardenStore.testGarden(in: context)
        ContentView(garden: garden, apiTimer: ApiTimer())
            .environment(\.managedObjectContext, context)
    }
}
