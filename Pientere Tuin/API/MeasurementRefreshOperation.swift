//
//  MeasurementRefreshOperation.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 24/08/2023.
//

import Foundation
import CoreData

class MeasurementRefreshOperation: Operation {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    override func main() {
        let garden = GardenStore.getGarden(in: context)
        if garden.apiKey != nil {
            Task {
                try? await ApiHandler.shared.updateTuinData(context: context, garden: garden)
            }
        }
    }
}
