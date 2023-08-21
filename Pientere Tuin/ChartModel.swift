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
        
    func reloadData(measurements: SectionedFetchResults<Date, MeasurementProjection>) {
        chartData = getChartData(measurements: measurements)
        chartAverage = getAverage(data: chartData)
    }
    
    
    private func getHourlyMeasurements(measurements: SectionedFetchResults<Date, MeasurementProjection>) -> [ChartableMeasurement] {
        var hourlyMeasurements: [ChartableMeasurement] = []

        for section in measurements {
            for measurement in section {
                hourlyMeasurements.append(ChartableMeasurement(date: measurement.measuredAt ?? Date(), moisturePercentage: measurement.moisturePercentage, soilTemperature: measurement.temperatureCelcius))
            }
        }
        return hourlyMeasurements
    }
    
    private func getDailyAverages(measurements: SectionedFetchResults<Date, MeasurementProjection>) -> [ChartableMeasurement] {
        var averageHumidities: [ChartableMeasurement] = []

        for section in measurements {
            let averages = MeasurementStore.getAverage(measurements: section)
            averageHumidities.append(ChartableMeasurement(date: section.id, moisturePercentage: averages.moisturePercentage, soilTemperature: averages.soilTemperature))
        }
        
        return averageHumidities
    }
    
    private func getAverage(data: [ChartableMeasurement]) -> MeasurementAverage {
        let sumMoisture = data.reduce(0) {
            $0 + $1.moisturePercentage
        }
        let sumTemperature = data.reduce(0) {
            $0 + $1.soilTemperature
        }
        let count = Float(data.count)
        return MeasurementAverage(moisturePercentage: sumMoisture/count, soilTemperature: sumTemperature/count)
    }
    
    private func getChartData(measurements: SectionedFetchResults<Date, MeasurementProjection>) -> [ChartableMeasurement] {
        switch preferences.chartScale {
        case .day, .week:
            return getHourlyMeasurements(measurements: measurements)
        case .month, .all:
            return getDailyAverages(measurements: measurements)
        }
    }
}
