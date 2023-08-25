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
    var chartType: ChartType
    
    var valueUnit: String {
        switch chartType {
        case .moisture:
            return "%"
        case .temperature:
            return "°C"
        }
    }
    
    var valueSpecifier: String {
        switch chartType {
        case .moisture:
            return "%.1f"
        case .temperature:
            return "%.0f"
        }
    }
    
    var typeIcon: Image {
        switch chartType {
        case .moisture:
            return Image(systemName: "drop.fill")
        case .temperature:
            return Image(systemName: "thermometer.medium")
        }
    }
    
    var typeText: String {
        switch chartType {
        case .moisture:
            return "vochtigheid bodem"
        case .temperature:
            return "temperatuur bodem"
        }
    }
    
    var typeColor: Color {
        switch chartType {
        case .moisture:
            return .blue
        case .temperature:
            return .green
        }
    }
    
    init(chartType: ChartType) {
        self.chartType = chartType
    }
        
    func reloadData(measurements: SectionedFetchResults<Date, MeasurementProjection>) {
        chartData = getChartData(measurements: measurements)
        chartAverage = getAverage(measurements: chartData)
        latestMeasurement = measurements.last?.last
    }
    
    private func getHourlyMeasurements(measurements: SectionedFetchResults<Date, MeasurementProjection>) -> [ChartableMeasurement] {
        var hourlyMeasurements: [ChartableMeasurement] = []

        for section in measurements {
            for measurement in section {
                if let value = getValue(item: measurement, chartType: chartType) {
                    hourlyMeasurements.append(ChartableMeasurement(date: measurement.measuredAt ?? Date(), value: value))
                }
            }
        }
        return hourlyMeasurements
    }
    
    private func getValue(item: MeasurementProjection, chartType: ChartType) -> Float? {
        switch chartType {
        case .moisture:
            return item.moisturePercentage*100
        case .temperature:
            if let temperature = item.temperatureCelcius?.floatValue {
                return temperature
            }
        }
        return nil
    }
    
    private func getDailyAverages(measurements: SectionedFetchResults<Date, MeasurementProjection>) -> [ChartableMeasurement] {
        var averageHumidities: [ChartableMeasurement] = []

        for section in measurements {
            let averages = MeasurementStore.getAverage(measurements: section, type: chartType)
            averageHumidities.append(ChartableMeasurement(date: section.id, value: averages.averageValue))
        }
        
        return averageHumidities
    }
    
    private func getAverage(measurements: [ChartableMeasurement]) -> MeasurementAverage {
        let sum = measurements.reduce(0) {
            $0 + $1.value
        }
       
        let max = measurements.reduce(0, { partialResult, measurement in
            Float.maximum(partialResult, measurement.value)
        })
        let min = measurements.reduce(100, { partialResult, measurement in
            Float.minimum(partialResult, measurement.value)
        })
        let count = Float(measurements.count)
        return MeasurementAverage(averageValue: sum/count, minValue: min, maxValue: max)
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
        switch chartType {
        case .moisture:
            if let averages = chartAverage {
                return 0.0...(averages.maxValue*1.1)
            } else {
                return 0...50
            }
        case .temperature:
            if let averages = chartAverage {
                return (averages.minValue*0.9)...(averages.maxValue*1.1)
            } else {
                return -20...40
            }
        }
        
    }
    
    func getDryValue() -> Float? {
        if let measurement = latestMeasurement {
            return measurement.stressHumidity?.upperBound
        }
        return nil
    }
}

struct ChartableMeasurement: Identifiable {
    var date: Date
//    var moisturePercentage: Float
//    var temperatureCelcius: Float
    var value: Float
    var id = UUID()
}
