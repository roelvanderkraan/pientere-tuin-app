//
//  SwiftUIView.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 15/08/2023.
//

import SwiftUI
import SimpleAnalytics
import OpenAPIRuntime

struct LaunchView: View {
    @ObservedObject var garden: Garden
    @Binding var isPresented: Bool
    @State var isError: Bool = false
    @State var errorMessage: String?
    @State var isValidating = false
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading) {
                        Text("Deze app toont de metingen van je Pientere Tuinen sensor.")
                        Text("Om je Pientere Tuinen data te zien heb je een API key nodig. Deze kan je vinden op de Pientere Tuinen website.")
                    }
                    
                    Link(destination: URL(string: "https://service-portal.platform.wecity.nl/api-subscriptions")!) {
                        Label("Mijn Pientere Tuin", systemImage: "link")
                    }
                    .buttonStyle(.bordered)
                    .listRowSeparator(.hidden)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    
                    Text("Plak je API key in dit veld:")
                        .listRowSeparator(.hidden)
                    
                    TextField("API key", text: Binding($garden.apiKey, replacingNilWith: ""))
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .fontDesign(.monospaced)
                        .minimumScaleFactor(0.25)
                        .bold()
                        .onSubmit {
                            validateApiKey()
                        }
                        .submitLabel(.done)
                    if let errorMessage = errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .listRowSeparator(.hidden)
                    }
                    if (isValidating) {
                        HStack {
                            ProgressView()
                            Text(" API key aan het controleren")
                        }
                        .listRowSeparator(.hidden)
                    }
                    
                    
                    PasteButton(payloadType: String.self) { strings in
                        guard let first = strings.first else { return }
                        garden.apiKey = first.trimmingCharacters(in: .whitespacesAndNewlines)
                        validateApiKey()
                    }
                    .listRowSeparator(.hidden)
                    .disabled(isValidating)
                    
                    Button {
                        validateApiKey()
                    } label: {
                        Text("Klaar")
                            .frame(maxWidth: .infinity)
                    }
                    .scaledToFill()
                    .buttonStyle(.borderedProminent)
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .font(.headline)
                    .disabled(isValidating)
                    
                    
                }
                Section {
                    Text("Nog geen Pientere Tuinen sensor?")
                    VStack(alignment: .leading) {
                        Link(destination: URL(string: "https://pienteretuinen.nl/")!) {
                            Text("Vraag een sensor aan")
                        }
                    }
                    .listRowSeparator(.hidden)
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
            .toolbar {
                ToolbarItem {
                    Button("Klaar") {
                        validateApiKey()
                    }
                }
            }
            .navigationTitle("Welkom")
            .headerProminence(.increased)
        }
        .onAppear {
            SimpleAnalytics.shared.track(path: ["launchView"])
        }
        
    }
    
    func validateApiKey() {
        isError = false
        isValidating = true
        guard garden.validateApiKey() else {
            withAnimation {
                isError = true
                isValidating = false
                errorMessage = "Vul een API key in"
            }
            SimpleAnalytics.shared.track(event: "error-api-keyempty", path: ["launchView"])
            return
        }
        Task {
            do {
                try await ApiHandler.shared.updateTuinData(context: viewContext, loadAll: true, garden: garden)
                isValidating = false
                dismiss()
            } catch APIError.notAuthorized {
                isError = true
                isValidating = false
                withAnimation {
                    errorMessage = "Deze API key heeft geen toegang tot de Pientere Tuinen API. Controleer of je de juiste key hebt ingevuld."
                }
                SimpleAnalytics.shared.track(event: "error-api-noaccess", path: ["launchView"])
            } catch is APIError {
                SimpleAnalytics.shared.track(event: "error-api-apierror", path: ["launchView"])
                isError = true
                isValidating = false
                withAnimation {
                    errorMessage = "Fout tijdens het valideren van de API key met de Pientere Tuinen server. Controleer of je de juiste key hebt ingevuld en probeer het later nog eens."
                }
            } catch (let error) {
                
                if let clientError = error as? ClientError {
                    debugPrint("Client error: \(error)")
                    SimpleAnalytics.shared.track(event: "error-api-clienterror", path: ["launchView"])
                } else {
                    debugPrint("Unknown error: \(error)")
                    SimpleAnalytics.shared.track(event: "error-api-unkown", path: ["launchView"])
                }
                isError = true
                withAnimation {
                    errorMessage = "Fout tijdens het valideren van de API key met de Pientere Tuinen server. Controleer of je de juiste key hebt ingevuld en probeer het later nog eens."
                }
                isPresented = false
            }
        }
    }
    
    func dismiss() {
        if !isError {
            isPresented = false
            SimpleAnalytics.shared.track(event: "dissmiss", path: ["launchView"])
        }
    }
}

struct GardenNew_Previews: PreviewProvider {
    static var previews: some View {
        let context =  PersistenceController.preview.container.viewContext

        LaunchView(garden: GardenStore.testNewGarden(in: context), isPresented: .constant(true))
            .environment(\.managedObjectContext, context)
    }
}
