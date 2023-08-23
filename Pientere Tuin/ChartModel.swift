//
//  ChartModel.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 21/08/2023.
//

import SwiftUI

class ChartModel: ObservableObject {
    @ObservedObject private var preferences = Preferences.shared
    
    @Published private(set) var chartData: [ChartableMeasurement] = []
    @Published private(set) var chartAverage: MeasurementAverage?
    private var latestMeasurement: MeasurementProjection?
        
    func reloadData(measurements: SectionedFetchResults<Date, MeasurementProjection>) {
        chartData = getChartData(measurements: measurements)
        chartAverage = getAverage(measurements: chartData)
        latestMeasurement = measurements.last?.last
    }
    
    
    private func getHourlyMeasurements(measurements: SectionedFetchResults<Date, MeasurementProjection>) -> [ChartableMeasurement] {
        var hourlyMeasurements: [ChartableMeasurement] = []

        for section in measurements {
            for measurement in section {
                hourlyMeasurements.append(ChartableMeasurement(date: measurement.measuredAt ?? Date(), moisturePercentage: measurement.moisturePercentage, temperatureCelcius: measurement.temperatureCelcius))
            }
        }
        return hourlyMeasurements
    }
    
    private func getDailyAverages(measurements: SectionedFetchResults<Date, MeasurementProjection>) -> [ChartableMeasurement] {
        var averageHumidities: [ChartableMeasurement] = []

        for section in measurements {
            let averages = MeasurementStore.getAverage(measurements: section)
            averageHumidities.append(ChartableMeasurement(date: section.id, moisturePercentage: averages.moisturePercentage, temperatureCelcius: averages.soilTemperature))
        }
        
        return averageHumidities
    }
    
    private func getAverage(measurements: [ChartableMeasurement]) -> MeasurementAverage {
        let sumMoisture = measurements.reduce(0) {
            $0 + $1.moisturePercentage
        }
        let sumTemperature = measurements.reduce(0) {
            $0 + $1.temperatureCelcius
        }
        let maxMoisture = measurements.reduce(0, { partialResult, measurement in
            Float.maximum(partialResult, measurement.moisturePercentage)
        })
        let minMoisture = measurements.reduce(100, { partialResult, measurement in
            Float.minimum(partialResult, measurement.moisturePercentage)
        })
        let maxTemperature = measurements.reduce(-30, { partialResult, measurement in
            Float.maximum(partialResult, measurement.temperatureCelcius)
        })
        let minTemperature = measurements.reduce(50, { partialResult, measurement in
            Float.minimum(partialResult, measurement.temperatureCelcius)
        })
        let count = Float(measurements.count)
        return MeasurementAverage(moisturePercentage: sumMoisture/count, soilTemperature: sumTemperature/count, minMoisture: minMoisture, minTemperature: minTemperature, maxMoisture: maxMoisture, maxTemperature: maxTemperature)
    }
    
    private func getChartData(measurements: SectionedFetchResults<Date, MeasurementProjection>) -> [ChartableMeasurement] {
        switch preferences.chartScale {
        case .day, .week:
            return getHourlyMeasurements(measurements: measurements)
        case .month, .all:
            return getDailyAverages(measurements: measurements)
        }
    }
    
    func getYScale() -> ClosedRange<Float> {
        if let averages = chartAverage {
            return 0.0...(averages.maxMoisture*100*1.1)
        } else {
            return 0...50
        }
    }
    
    func getDryValue() -> Float? {
        if let measurement = latestMeasurement {
            return measurement.stressHumidity?.upperBound
        }
        return nil
    }
}
