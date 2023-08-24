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
            var count = 0
            
            let sum = measurements.reduce(0.0) {
                if let temperature = $1.temperatureCelcius {
                    count += 1
                    return $0 + temperature.doubleValue
                }
                return $0
            }
           
            let max = measurements.reduce(0.0, { partialResult, measurement in
                if let temperature = measurement.temperatureCelcius {
                    return Double.maximum(partialResult, temperature.doubleValue)
                }
                return partialResult
            })
            
            let min = measurements.reduce(100.0, { partialResult, measurement in
                if let temperature = measurement.temperatureCelcius {
                    return Double.minimum(partialResult, temperature.doubleValue)
                }
                return partialResult
            })

            return MeasurementAverage(averageValue: Float(sum)/Float(count), minValue: Float(min), maxValue: Float(max))
        }
    }
}

struct MeasurementAverage {
    var averageValue: Float
    var minValue: Float
    var maxValue: Float
}
