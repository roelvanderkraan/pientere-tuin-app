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
        newGarden.apiKey = "ee3f7468-11fb-43b6-b870-49f9435524c1"
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
    

}
