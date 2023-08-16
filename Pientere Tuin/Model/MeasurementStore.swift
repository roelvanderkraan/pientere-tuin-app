//
//  MeasurementStore.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 16/08/2023.
//

import Foundation
import CoreData

struct MeasurementStore {
    static func addTestMeasurement(to viewContext: NSManagedObjectContext) -> MeasurementProjection {
        let measurement = MeasurementProjection(context: viewContext)
        measurement.measuredAt = Date()
        measurement.moisturePercentage = 0.20
        measurement.temperatureCelcius = 20
        measurement.apiUUID = UUID().uuidString
        measurement.inGarden = GardenStore.testNewGarden(in: viewContext)
        return measurement
    }
}
