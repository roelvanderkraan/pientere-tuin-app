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
        if count > 0 {
            return MeasurementAverage(averageValue: sum/count, minValue: min, maxValue: max)
        } else {
            return MeasurementAverage(averageValue: 0, minValue: 0, maxValue: 0)
        }
    }
    
    private func getChartData(measurements: SectionedFetchResults<Date, MeasurementProjection>) -> [ChartableMeasurement] {
        let data: [ChartableMeasurement]
        switch preferences.chartScale {
        case .day, .week:
            data = getHourlyMeasurements(measurements: measurements)
        case .month, .all:
            data = getDailyAverages(measurements: measurements)
        }
        
        // Sort in reverse chronological order (most recent first) so chart opens showing latest data
        return data.sorted { $0.date > $1.date }
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
    
    func scaleToVisibleDomain(chartScale: ChartScale) -> Int {
        switch chartScale {
        case .day:
            return 3600 * 24
        case .week:
            return 3600 * 24 * 7
        case .month:
            return 3600 * 24 * 30
        case .all:
            return  3600 * 24 * 365
        }
    }
    
    func getXScale() -> ClosedRange<Date> {
        guard !chartData.isEmpty else {
            let now = Date()
            return now...now
        }
        
        let sortedData = chartData.sorted { $0.date < $1.date }
        let startDate = sortedData.first!.date
        let endDate = sortedData.last!.date
        
        return startDate...endDate
    }
    
    func getVisibleDomain() -> ClosedRange<Date> {
        guard !chartData.isEmpty else {
            let now = Date()
            return now...now
        }
        
        let sortedData = chartData.sorted { $0.date < $1.date }
        let endDate = sortedData.last!.date
        
        // Calculate the start date based on the chart scale to show the most recent period
        let calendar = Calendar.current
        let startDate: Date
        
        switch preferences.chartScale {
        case .day:
            // Show the last 24 hours ending at the most recent data
            startDate = calendar.date(byAdding: .hour, value: -24, to: endDate) ?? endDate
        case .week:
            // Show the last 7 days ending at the most recent data
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .month:
            // Show the last 30 days ending at the most recent data
            startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        case .all:
            // For "all" view, show all data but position at the end
            startDate = sortedData.first!.date
        }
        
        return startDate...endDate
    }
}

struct ChartableMeasurement: Identifiable {
    var date: Date
//    var moisturePercentage: Float
//    var temperatureCelcius: Float
    var value: Float
    var id = UUID()
}
