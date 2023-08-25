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
    @State var isDeletingAll: Bool = false
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField(text: Binding($garden.apiKey, replacingNilWith: "")) {
                        Text("API key")
                    }
                    .minimumScaleFactor(0.25)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .fontDesign(.monospaced)
                    .bold()
                    if let url = URL(string: "https://service-portal.platform.wecity.nl/api-subscriptions") {
                        Link("Vind je API key hier", destination: url)
                    }
                } header: {
                    Text("API key")
                } footer: {
                    Text("Vul hier de API key in uit je Pientere Tuin account.")
                }
                Section("Tuin") {
                    Link(destination: URL(string: "https://service-portal.platform.wecity.nl/pientere-tuinen")!) {
                        Label("Bewerk tuininformatie", systemImage: "safari")
                    }
                }
                Section {
                    Link(destination: URL(string: "https://help.wecity.nl/pientere-tuinen")!) {
                        Label("Knowledgebase", systemImage: "graduationcap")
                    }
                    Link(destination: URL(string: "mailto:roel@goeieplantjes.nl")!)  {
                        Label("App feedback", systemImage: "paperplane")
                    }
                } header: {
                    Text("Information")
                } footer: {
                    Text("Ik ben benieuwd hoe ik de app kan verbeteren.")
                }
                Section {
                    Button {
                        Task {
                            try? await ApiHandler.shared.updateTuinData(context: viewContext, loadAll: true, garden: garden)
                        }
                        isPresented.toggle()
                    } label: {
                        Label("Metingen opnieuw inladen", systemImage: "arrow.counterclockwise")
                    }
                    Button(role: .destructive) {
                        isDeletingAll.toggle()
                    } label: {
                        Label("Verwijder alle metingen", systemImage: "trash")
                            .foregroundColor(.red)
                        
                    }
                } header: {
                    Text("Data management")
                }
            }
            .textFieldStyle(.roundedBorder)
            .listSectionSeparator(.hidden)
            .toolbar {
                ToolbarItem {
                    Button("Klaar") {
                        isPresented.toggle()
                    }
                }
            }
            .navigationTitle("Instellingen")
            .alert("Verwijder alle metingen", isPresented: $isDeletingAll) {
                Button("Verwijder", role: .destructive) {
                    GardenStore.deleteAllMeasurements(garden: garden, from: viewContext)
                    isPresented.toggle()
                }
                .keyboardShortcut(.defaultAction)
                Button("Annuleer", role: .cancel) {
                    
                }
            } message: {
                Text("Weet je het zeker dat je alle metingen wilt verwijderen?")
            }
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
