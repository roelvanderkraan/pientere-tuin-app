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
                            predicate: .filter(key: "measuredAt", date: Date(), scale: chartScale)))
                        .environment(\.managedObjectContext, viewContext)
                }
                Section {
                    TemperatureItem(
                        measurements: FetchRequest<MeasurementProjection>(
                            sortDescriptors: [NSSortDescriptor(keyPath: \MeasurementProjection.measuredAt, ascending: false)],
                            predicate: .filter(key: "measuredAt", date: Date(), scale: chartScale)))
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
                            try? await apiHandler.updateTuinData(context: viewContext, loadAll: true)
                        }
                    }
                }
            }
            .navigationTitle("Pientere Tuin")
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

enum ChartScale: String, CaseIterable, Identifiable {
    case week
    case month
    case day
    case all
    var id: Self { self }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
