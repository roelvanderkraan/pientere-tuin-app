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
                Section("Garden") {
                    Link(destination: URL(string: "https://service-portal.platform.wecity.nl/pientere-tuinen")!) {
                        Label("Edit garden information", systemImage: "safari")
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
                    Text("Please let me know how I can make this app more useful for you.")
                }
                Section {
                    Button {
                        Task {
                            try? await ApiHandler.shared.updateTuinData(context: viewContext, loadAll: true, garden: garden)
                        }
                        isPresented.toggle()
                    } label: {
                        Label("Reload measurements", systemImage: "arrow.counterclockwise")
                    }
                    Button(role: .destructive) {
                        isDeletingAll.toggle()
                    } label: {
                        Label("Delete all measurements", systemImage: "trash")
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
                    Button("Done") {
                        isPresented.toggle()
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Delete all measurements", isPresented: $isDeletingAll) {
                Button("Delete", role: .destructive) {
                    GardenStore.deleteAllMeasurements(garden: garden, from: viewContext)
                    isPresented.toggle()
                }
                .keyboardShortcut(.defaultAction)
                Button("Cancel", role: .cancel) {
                    
                }
            } message: {
                Text("Are you sure you want to delete all measurements? This cannot be undone.")
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
