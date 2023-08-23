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
    
    static func getAverage(measurements: any Collection<MeasurementProjection>, type: ChartType) -> MeasurementAverage {
        switch type {
        case .moisture:
            let sum = measurements.reduce(0) {
                $0 + $1.moisturePercentage*100
            }
           
            let max = measurements.reduce(0, { partialResult, measurement in
                Float.maximum(partialResult, measurement.moisturePercentage*100)
            })
            let min = measurements.reduce(100, { partialResult, measurement in
                Float.minimum(partialResult, measurement.moisturePercentage*100)
            })
            let count = Float(measurements.count)
            return MeasurementAverage(averageValue: sum/count, minValue: min, maxValue: max)
        case .temperature:
            let sum = measurements.reduce(0) {
                $0 + $1.temperatureCelcius
            }
           
            let max = measurements.reduce(0, { partialResult, measurement in
                Float.maximum(partialResult, measurement.temperatureCelcius)
            })
            let min = measurements.reduce(100, { partialResult, measurement in
                Float.minimum(partialResult, measurement.temperatureCelcius)
            })
            let count = Float(measurements.count)
            return MeasurementAverage(averageValue: sum/count, minValue: min, maxValue: max)
        }
    }
}

struct MeasurementAverage {
    var averageValue: Float
    var minValue: Float
    var maxValue: Float
}
