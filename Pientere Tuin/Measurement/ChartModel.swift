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
    @Published private(set) var cachedDataRange: ClosedRange<Date>?
    private var latestMeasurement: MeasurementProjection?
    let chartType: ChartType
    
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
        chartData.sort { $0.date < $1.date }
        
        chartAverage = getAverage(measurements: chartData)
        cachedDataRange = computeDataRange()
        latestMeasurement = measurements.last?.last
    }

    private func computeDataRange() -> ClosedRange<Date>? {
        guard let first = chartData.first?.date, let last = chartData.last?.date else { return nil }
        return first...last
    }
    
    /// Generic aggregation method that groups measurements by date components
    private func aggregateMeasurements(
        _ measurements: SectionedFetchResults<Date, MeasurementProjection>,
        components: [Calendar.Component]
    ) -> [ChartableMeasurement] {
        let calendar = Calendar.current
        let allMeasurements = measurements.flatMap { $0 }
        
        // Group by creating a normalized date (start of hour/day/month/year)
        let groups = Dictionary(grouping: allMeasurements) { item -> Date in
            guard let measuredDate = item.measuredAt else {
                return Date.distantPast
            }
            
            // Create a date with only the specified components
            let dateComps = calendar.dateComponents(Set(components), from: measuredDate)
            return calendar.date(from: dateComps) ?? Date.distantPast
        }
        
        // Calculate average for each group and sort by date
        return groups.compactMap { date, group -> ChartableMeasurement? in
            guard date != Date.distantPast else { return nil }
            let averages = MeasurementStore.getAverage(measurements: group, type: chartType)
            return ChartableMeasurement(date: date, value: averages.averageValue)
        }.sorted { $0.date < $1.date }
    }
    
    private func getDailyAverages(measurements: SectionedFetchResults<Date, MeasurementProjection>) -> [ChartableMeasurement] {
        // Use pre-sectioned data (already grouped by day)
        return measurements.map { section in
            let averages = MeasurementStore.getAverage(measurements: section, type: chartType)
            return ChartableMeasurement(date: section.id, value: averages.averageValue)
        }
    }
    
    private func getAverage(measurements: [ChartableMeasurement]) -> MeasurementAverage {
        guard !measurements.isEmpty else {
            return MeasurementAverage(averageValue: 0, minValue: 0, maxValue: 0)
        }
        
        let values = measurements.map(\.value)
        let sum = values.reduce(0, +)
        let average = sum / Float(measurements.count)
        let min = values.min() ?? 0
        let max = values.max() ?? 0
        
        return MeasurementAverage(averageValue: average, minValue: min, maxValue: max)
    }
    
    private func getChartData(measurements: SectionedFetchResults<Date, MeasurementProjection>) -> [ChartableMeasurement] {
        switch preferences.chartScale {
        case .day, .week:
            return aggregateMeasurements(measurements, components: [.year, .month, .day, .hour])
        case .month:
            return getDailyAverages(measurements: measurements)
        case .year:
            return aggregateMeasurements(measurements, components: [.year, .month])
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
        latestMeasurement?.stressHumidity?.upperBound
    }
}

struct ChartableMeasurement: Identifiable {
    var date: Date
    var value: Float
    var id: Date { date }
}
