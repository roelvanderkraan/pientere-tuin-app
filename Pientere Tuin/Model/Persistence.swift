//
//  Persistence.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 09/08/2023.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let newGarden = Garden(context: viewContext)
        let calendar = Calendar.current
        newGarden.apiKey = "ee3f7468-11fb-43b6-b870-49f9435524c1"
        newGarden.name = "Jonge Jan tuin"
        let date = Date()
        for count in 0..<50 {
            let newMeasurement = MeasurementProjection(context: viewContext)
            newMeasurement.measuredAt = calendar.date(byAdding: DateComponents(hour: -5*count), to: date)
            newMeasurement.moisturePercentage = Float(count) * 0.05
            newMeasurement.temperatureCelcius = NSNumber(value: Float(count) * 5.0)
            newMeasurement.apiUUID = UUID().uuidString
            newMeasurement.soilTypeObject = .gardenSoil
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.studio.skipper.Pientere-Tuin")!
        let storeURL = containerURL.appendingPathComponent("PientereTuin.sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)
        container = NSPersistentContainer(name: "Pientere_Tuin")
        container.persistentStoreDescriptions = [description]
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
