//
//  Pientere_TuinApp.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 09/08/2023.
//

import SwiftUI

@main
struct Pientere_TuinApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(garden: GardenStore.getGarden(in: persistenceController.container.viewContext))
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
