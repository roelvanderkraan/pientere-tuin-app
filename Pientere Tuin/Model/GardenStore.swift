//
//  GardenStore.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 12/08/2023.
//

import Foundation
import CoreData

struct GardenStore {
    static func getGarden(in viewContext: NSManagedObjectContext) -> Garden {
        let fetchRequest = Garden.fetchRequest()

        do {
            let gardens = try viewContext.fetch(fetchRequest)
            if let garden = gardens.first {
                return garden
            }
        } catch {
            // Error fetching garden, do nothing
        }
        
        // Add a new garden
        let garden = Garden(context: viewContext)
        return garden
    }
    
    static func testGarden(in context: NSManagedObjectContext) -> Garden {
        let newGarden = Garden(context: context)
        newGarden.apiKey = testAPIKey
        newGarden.name = "Jonge Jan tuin"
        return newGarden
    }
    
    static func testNewGarden(in context: NSManagedObjectContext) -> Garden {
        let newGarden = Garden(context: context)
        return newGarden
    }
    
    static func deleteAllMeasurements(garden: Garden, from viewContext: NSManagedObjectContext) {
        let fetchRequest = MeasurementProjection.fetchRequest()
        let predicate = NSPredicate(format: "inGarden = %@", garden)
        fetchRequest.predicate = predicate
        do {
            let measurements = try viewContext.fetch(fetchRequest)
            for measurement in measurements {
                viewContext.delete(measurement)
            }
            try viewContext.save()
        } catch {
            debugPrint("Error deleting measurements from garden")
        }
    }
    
    static func delete(garden: Garden, from viewContext: NSManagedObjectContext) {
        viewContext.delete(garden)
        do {
            try viewContext.save()
        } catch {
            debugPrint("Error deleting garden \(garden)")
        }
    }
    
    static private var testAPIKey: String {
        get {
            // 1
            guard let filePath = Bundle.main.path(forResource: "testAPIKey", ofType: "plist") else {
                fatalError("Couldn't find file 'testAPIKey.plist'.")
            }
            // 2
            let plist = NSDictionary(contentsOfFile: filePath)
            guard let value = plist?.object(forKey: "PIENTERE_TUIN_API") as? String else {
                fatalError("Couldn't find key 'PIENTERE_TUIN_API' in 'testAPIKey.plist'.")
            }
            // 3
            if (value.starts(with: "_")) {
                fatalError("Get an API key from Mijn Pientere Tuinen and add it to testAPIKey.plist as PIENTERE_TUIN_API")
            }
            return value
        }
    }
}
