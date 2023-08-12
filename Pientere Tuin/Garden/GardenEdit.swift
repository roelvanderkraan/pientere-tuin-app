//
//  GardenEdit.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 12/08/2023.
//

import SwiftUI
import CoreData

struct GardenEdit: View {
    @ObservedObject var garden: Garden
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section("Name") {
                    TextField("Name", text: Binding($garden.name, replacingNilWith: ""))
                }
                Section {
                    TextField(text: Binding($garden.apiKey, replacingNilWith: "")) {
                        Text("API key")
                    }
                    .disableAutocorrection(true)
                    if let url = URL(string: "https://service-portal.platform.wecity.nl/api-subscriptions") {
                        Link("Vind je API key hier", destination: url)
                    }
                } header: {
                    Text("API key")
                } footer: {
                    Text("Vul hier de API key in uit je Pientere Tuin account.")
                }
            }
            .textFieldStyle(.roundedBorder)
            .listSectionSeparator(.hidden)
            .listStyle(.grouped)
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        isPresented.toggle()
                        // should call save on context here
                    }
                }
            }
            .navigationTitle("Pientere Tuin")
        }
    }
}

struct GardenEdit_Previews: PreviewProvider {
    static var previews: some View {
        let context =  PersistenceController.preview.container.viewContext
        
        GardenEdit(garden: GardenStore.testGarden(in: context), isPresented: .constant(true))
            .environment(\.managedObjectContext, context)
    }
}
