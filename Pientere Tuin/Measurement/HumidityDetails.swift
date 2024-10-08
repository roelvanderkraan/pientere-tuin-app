//
//  TemperatureDetails.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 16/08/2023.
//

import SwiftUI
import SimpleAnalytics

struct HumidityDetails: View {
    @Environment(\.managedObjectContext) private var viewContext
        
    var body: some View {
        List {
            Section {
                MesurementChart(chartModel: ChartModel(chartType: .moisture))
                .environment(\.managedObjectContext, viewContext)
                .frame(idealHeight: 400)
            }

            Section("Over bodemvochtigheid") {
                Text("Water is van levensbelang voor planten. Zo'n 80 to 95% van het gewicht van een gezonde plant bestaat uit water. Bij te weinig water verwelken planten. En bij te veel water verdrinken ze. Te veel of te weinig water geeft planten stress. Daarom is het voor een optimale plantengroei van cruciaal belang dat de plant over de juiste hoeveelheid water beschikt. De juiste hoeveelheid vocht verschilt per grondsoort.")
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
        .navigationTitle("Vochtigheid bodem")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.grouped)
        .headerProminence(.increased)
        .onAppear {
            SimpleAnalytics.shared.track(path: ["humidityDetails"])
        }
    }
}

struct HumidityDetails_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HumidityDetails()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
