//
//  TemperatureDetails.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 16/08/2023.
//

import SwiftUI

struct HumidityDetails: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var chartScale: ChartScale = .month
    
    var body: some View {
        List {
            Section {
                Picker("Chart scale", selection: $chartScale) {
                    Text("D").tag(ChartScale.day)
                    Text("W").tag(ChartScale.week)
                    Text("M").tag(ChartScale.month)
                    Text("All").tag(ChartScale.all)
                }
                .pickerStyle(.segmented)
                HumidityItem(
                    measurements: FetchRequest<MeasurementProjection>(
                        sortDescriptors: [NSSortDescriptor(keyPath: \MeasurementProjection.measuredAt, ascending: false)],
                        predicate: .filter(key: "measuredAt", date: Date(), scale: chartScale)),
                    scale: $chartScale)
                .environment(\.managedObjectContext, viewContext)
                .frame(idealHeight: 300)
            }
            Section("Over Humidity") {
                Text("Water is van levensbelang voor planten. Zo'n 80 to 95% van het gewicht van een gezonde plant bestaat uit water. Bij te weinig water verwelken planten. En bij te veel water verdrinken ze. Te veel of te weinig water geeft planten stress. Daarom is het voor een optimale plantengroei van cruciaal belang dat de plant over de juiste hoeveelheid water beschikt. De juiste hoeveelheid vocht verschilt per grondsoort.")
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
        .navigationTitle("Humidity")
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
