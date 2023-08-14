//
//  Pientere_TuinApp.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 09/08/2023.
//

import SwiftUI
import CoreData
import BackgroundTasks

@main
struct Pientere_TuinApp: App {
    @Environment(\.scenePhase) private var phase
    let persistenceController = PersistenceController.shared
    @State private var apiTimer = ApiTimer()

    var body: some Scene {
        WindowGroup {
            ContentView(
                garden: GardenStore.getGarden(in: persistenceController.container.viewContext),
                apiTimer: apiTimer
            )
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .onChange(of: phase) { newPhase in
            switch newPhase {
            //case .background: scheduleAppRefresh()
            case .active:
                if apiTimer.isParseAllowed() {
                    Task {
                        await refreshData()
                    }
                }
            default: break
            }
        }
        
    }
    
    /// Refreshes data from API in background thread
    /// Should run +/- every hour, since data in the API is only updated hourly
    private func refreshData() async {
        let apiHandler = ApiHandler()
        let viewContext = persistenceController.container.newBackgroundContext()
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        let garden = GardenStore.getGarden(in: viewContext)
        try? await apiHandler.updateTuinData(context: viewContext, garden: garden)
    }
    
    /// Schedules background refresh of data, every 15 minutes
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "studio.skipper.Pientere-Tuin.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
