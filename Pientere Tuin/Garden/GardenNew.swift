//
//  SwiftUIView.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 15/08/2023.
//

import SwiftUI

struct GardenNew: View {
    @ObservedObject var garden: Garden
    @Binding var isPresented: Bool
    @State var isError: Bool = false
    @State var errorMessage: String?
    var apiHandler: ApiHandler
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            List {
                VStack(alignment: .leading) {
                    Text("To see your sensor data in this app, get your API key from the Pientere Tuinen website.")
                }

                Link(destination: URL(string: "https://service-portal.platform.wecity.nl/api-subscriptions")!) {
                    Label("Open the website", systemImage: "safari")
                }
                    .buttonStyle(.bordered)
                    .listRowSeparator(.hidden)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))

                Text("Paste the API key in this textfield:")
                    .listRowSeparator(.hidden)

                TextField("API key", text: Binding($garden.apiKey, replacingNilWith: ""))
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .fontDesign(.monospaced)
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
                PasteButton(payloadType: String.self) { strings in
                    guard let first = strings.first else { return }
                    garden.apiKey = first.trimmingCharacters(in: .whitespacesAndNewlines)
                    validateApiKey()
                }
                    .listRowSeparator(.hidden)
                
                Button {
                    validateApiKey()
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .scaledToFill()
                .buttonStyle(.borderedProminent)
                .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .font(.headline)
                //...listRowSeparator(.hidden)
            }
            .listStyle(.automatic)
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        validateApiKey()
                    }
                }
            }
            .navigationTitle("Get started")
        }
        
    }
    
    func validateApiKey() {
        isError = false
        guard garden.validateApiKey() else {
            withAnimation {
                isError = true
                errorMessage = "Please enter an API key"
            }
            return
        }
        Task {
            do {
                try await apiHandler.updateTuinData(context: viewContext, loadAll: true, garden: garden)
                dismiss()
            } catch is NotAuthorizedError {
                isError = true
                withAnimation {
                    errorMessage = "This API key has no access to the Pientere Tuinen API. Check if you have entered the correct key."
                }
            } catch {
                isError = true
                withAnimation {
                    errorMessage = "Error while validating your API key with the Pientere Tuinen server. Please check if you entered the correct key and try again later."
                }
            }
        }
    }
    
    func dismiss() {
        if !isError {
            isPresented = false
        }
    }
}

struct GardenNew_Previews: PreviewProvider {
    static var previews: some View {
        let context =  PersistenceController.preview.container.viewContext

        GardenNew(garden: GardenStore.testNewGarden(in: context), isPresented: .constant(true), apiHandler: ApiHandler())
            .environment(\.managedObjectContext, context)
    }
}
