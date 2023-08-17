//
//  MeasurementStore.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 16/08/2023.
//

import Foundation
import CoreData
import SwiftUI

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
    
    static func getAverage(measurements: FetchedResults<MeasurementProjection>) -> MeasurementAverage {
        let sumMoisture = measurements.reduce(0) {
            $0 + $1.moisturePercentage
        }
        let sumTemperature = measurements.reduce(0) { partialResult, measurement in
            partialResult + measurement.temperatureCelcius
        }
        let count = Float(measurements.count)
        return MeasurementAverage(moisturePercentage: sumMoisture/count, soilTemperature: sumTemperature/count)
    }
    
    struct MeasurementAverage {
        var moisturePercentage: Float
        var soilTemperature: Float
    }
}
