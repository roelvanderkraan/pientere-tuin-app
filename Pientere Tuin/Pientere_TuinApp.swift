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
    @StateObject private var weatherData = WeatherData.shared
    
//    init() {
//        // MARK: Registering Launch Handlers for Tasks
//        BGTaskScheduler.shared.register(forTaskWithIdentifier: "studio.skipper.Pientere-Tuin.refresh", using: nil) { task in
//            self.handleAppRefresh(task: task as! BGAppRefreshTask)
//        }
//    }

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
            case .background: scheduleAppRefresh()
            case .active:
                if apiTimer.isParseAllowed() {
                    Task {
                        await refreshData()
                    }
                }
                refreshWeatherData()
            default: break
            }
        }
        .backgroundTask(.appRefresh("studio.skipper.Pientere-Tuin.refresh")) {
            await handleAppRefresh()
        }
        
    }
    
    /// Refreshes data from API in background thread
    /// Should run +/- every hour, since data in the API is only updated hourly
    private func refreshData() async {
        let viewContext = persistenceController.container.newBackgroundContext()
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        let garden = GardenStore.getGarden(in: viewContext)
        if garden.apiKey != nil {
            try? await ApiHandler.shared.updateTuinData(context: viewContext, garden: garden)
        }
    }
    
    /// Schedules background refresh of data, every 15 minutes
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "studio.skipper.Pientere-Tuin.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30*60)
        try? BGTaskScheduler.shared.submit(request)
        debugPrint("Task submitted")
        // testcode: e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"studio.skipper.Pientere-Tuin.refresh"]
    }
    
    private func refreshWeatherData() {
        Task.detached { @MainActor in
            if let lastMeasurement = MeasurementStore.getLastMeasurement(in: persistenceController.container.newBackgroundContext()) {
                await weatherData.dailyForecast(for: lastMeasurement.location())
            }
        }
    }
    
    private func handleAppRefresh() async {
        scheduleAppRefresh()
        await refreshData()
    }
}
