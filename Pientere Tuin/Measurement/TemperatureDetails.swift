//
//  TemperatureDetails.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 16/08/2023.
//

import SwiftUI

struct TemperatureDetails: View {
    @Environment(\.managedObjectContext) private var viewContext    
    
    var body: some View {
        List {
            Section {
                TemperatureItem()
                    .environment(\.managedObjectContext, viewContext)
                    .frame(idealHeight: 300)
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
        .navigationTitle("Temperature")
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