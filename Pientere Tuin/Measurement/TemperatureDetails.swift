//
//  TemperatureDetails.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 16/08/2023.
//

import SwiftUI
import SwiftSimpleAnalytics

struct TemperatureDetails: View {
    @Environment(\.managedObjectContext) private var viewContext    
    
    var body: some View {
        List {
            Section {
                MesurementChart(chartModel: ChartModel(chartType: .temperature))
                    .environment(\.managedObjectContext, viewContext)
                    .frame(idealHeight: 400)
            }
            Section {
                NavigationLink {
                    MeasurementList()
                        .environment(\.managedObjectContext, viewContext)
                } label: {
                    Text("Alle metingen")
                }
            }
        }
        .navigationTitle("Temperatuur bodem")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.grouped)
        .onAppear {
            SimpleAnalytics.shared.track(path: ["temperatureDetails"])
        }
    }
}

struct TemperatureDetails_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TemperatureDetails()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
