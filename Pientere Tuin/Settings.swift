//
//  GardenEdit.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 12/08/2023.
//

import SwiftUI
import CoreData
import SwiftSimpleAnalytics

struct Settings: View {
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
                        Label("Knowledgebase Pientere Tuinen", systemImage: "graduationcap")
                    }
                    Link(destination: URL(string: "mailto:contact-project+roelie-pientere-tuin-48445756-issue-@incoming.gitlab.com?subject=Pientere Tuin app feedback")!)  {
                        Label("App feedback", systemImage: "paperplane")
                    }
                } header: {
                    Text("Informatie")
                } footer: {
                    Text("Ik ben benieuwd hoe ik de app voor je kan verbeteren.")
                }
                Section {
                    Button {
                        Task {
                            try? await ApiHandler.shared.updateTuinData(context: viewContext, loadAll: true, garden: garden)
                        }
                        isPresented.toggle()
                        SimpleAnalytics.shared.track(event: "update-data", path: ["settings"])
                    } label: {
                        Label("Metingen opnieuw inladen", systemImage: "arrow.counterclockwise")
                    }
                    Button(role: .destructive) {
                        isDeletingAll.toggle()
                        SimpleAnalytics.shared.track(event: "delete-data", path: ["settings"])
                    } label: {
                        Label("Verwijder alle metingen", systemImage: "trash")
                            .foregroundColor(.red)
                        
                    }
                } header: {
                    Text("Databeheer")
                }
                Link(destination: URL(string: "https://www.roelvanderkraan.nl/?ref=pienteretuinapp")!) {
                    Text("Gemaakt met 💚 door Roel")
                }
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
                Link(destination: URL(string: "https://www.roelvanderkraan.nl/pienteretuin/privacy-policy?ref=pienteretuinapp")!) {
                    Text("\(Image(systemName: "lock.shield")) Privacy")
                }
                .listRowBackground(Color.clear)
            }
            .textFieldStyle(.roundedBorder)
            .listSectionSeparator(.hidden)
            .toolbar {
                ToolbarItem {
                    Button("Klaar") {
                        SimpleAnalytics.shared.track(event: "dismiss", path: ["settings"])
                        isPresented.toggle()
                    }
                }
            }
            .navigationTitle("Instellingen")
            .alert("Verwijder alle metingen", isPresented: $isDeletingAll) {
                Button("Verwijder", role: .destructive) {
                    GardenStore.deleteAllMeasurements(garden: garden, from: viewContext)
                    isPresented.toggle()
                    SimpleAnalytics.shared.track(event: "delete-data-confirmed", path: ["settings"])
                }
                .keyboardShortcut(.defaultAction)
                Button("Annuleer", role: .cancel) {
                    SimpleAnalytics.shared.track(event: "delete-data-cancel", path: ["settings"])
                }
            } message: {
                Text("Weet je het zeker dat je alle metingen wilt verwijderen?")
            }
        }
        .onAppear {
            SimpleAnalytics.shared.track(path: ["settings"])
        }
    }
}

struct GardenEdit_Previews: PreviewProvider {
    static var previews: some View {
        let context =  PersistenceController.preview.container.viewContext
        
        Settings(garden: GardenStore.testGarden(in: context), isPresented: .constant(true))
            .environment(\.managedObjectContext, context)
    }
}
