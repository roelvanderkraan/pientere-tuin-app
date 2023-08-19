//
//  HumidityItem.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 12/08/2023.
//

import SwiftUI
import Charts

struct HumidityItemDaily: View {
//    @FetchRequest(
//        sortDescriptors: [SortDescriptor(\.measuredAt, order: .reverse)],
//        animation: .default)
//    private var measurements: FetchedResults<MeasurementProjection>
    
    @SectionedFetchRequest<Date, MeasurementProjection>(
        sectionIdentifier: \.sectionMeasuredAt,
        sortDescriptors: [SortDescriptor(\.measuredAt, order: .reverse)]
    )
    private var sectionedMeasurements: SectionedFetchResults<Date, MeasurementProjection>
        
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var preferences = Preferences.shared
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker("Chart scale", selection: $preferences.chartScale) {
                Text("D").tag(ChartScale.day)
                Text("W").tag(ChartScale.week)
                Text("M").tag(ChartScale.month)
                Text("All").tag(ChartScale.all)
            }
            .pickerStyle(.segmented)
            HStack(alignment: .firstTextBaseline) {
                Text("\(Image(systemName: "drop.fill")) Average soil humidity")
                    .font(.system(.body, design: .default, weight: .medium))
                    .foregroundColor(.blue)
                Spacer()
            }
            HStack(alignment: .firstTextBaseline) {
//                Text("\(MeasurementStore.getAverage(measurements: measurements).moisturePercentage * 100, specifier: "%.1f")")
//                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("%")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Chart(getChartData()) { dayAverage in
                    LineMark(
                        x: .value("Day", dayAverage.date, unit: .hour),
                        y: .value("Moisture", dayAverage.moisturePercentage * 100)

                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.yellow, .green, .blue],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .alignsMarkStylesWithPlotArea()
                if preferences.chartScale == .day || preferences.chartScale == .month {
                    PointMark(
                        x: .value("Day", dayAverage.date, unit: .hour),
                        y: .value("Moisture", dayAverage.moisturePercentage * 100)
                        
                    )
                }
            }
            .chartForegroundStyleScale([
                "Moisture": .blue
            ])
            .chartLegend(.hidden)
            .padding([.trailing], 8)
            .chartYAxisLabel("%")
            .chartXAxis {
                switch preferences.chartScale {
                case .day:
                    AxisMarks(values: .stride(by: .hour, count: 5)) { value in
                        if let date = value.as(Date.self) {
                            let hour = Calendar.current.component(.hour, from: date)
                            switch hour {
                            case 0, 12:
                                AxisValueLabel(format: .dateTime.hour())
                            default:
                                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                            }
                        }
                        
                        AxisGridLine()
                        AxisTick()
                    }
                case .week:
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel(format: .dateTime.weekday())
                        }
                        
                        AxisGridLine()
                        AxisTick()
                    }
                case .month:
                    AxisMarks(values: .stride(by: .day, count: 5)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel(format: .dateTime.day())
                        }
                        
                        AxisGridLine()
                        AxisTick()
                    }
                case .all:
                    AxisMarks(values: .stride(by: .month, count: 1)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel(format: .dateTime.month())
                        }
                        
                        AxisGridLine()
                        AxisTick()
                    }
                }
            }
        }
        .padding([.bottom, .top], 8)
        .onChange(of: preferences.chartScale) { newValue in
            sectionedMeasurements.nsPredicate = .filter(key: "measuredAt", date: Date(), scale: newValue)
        }
        .onAppear {
            sectionedMeasurements.nsPredicate = .filter(key: "measuredAt", date: Date(), scale: preferences.chartScale)
        }
    }
    
    func getHourlyMeasurements() -> [ChartableMeasurement] {
        var hourlyMeasurements: [ChartableMeasurement] = []

        for section in sectionedMeasurements {
            for measurement in section {
                hourlyMeasurements.append(ChartableMeasurement(date: measurement.measuredAt ?? Date(), moisturePercentage: measurement.moisturePercentage, soilTemperature: measurement.temperatureCelcius))
            }
        }
        return hourlyMeasurements
    }
    func getDailyAverages() -> [ChartableMeasurement] {
        var averageHumidities: [ChartableMeasurement] = []

        for section in sectionedMeasurements {
            let averages = MeasurementStore.getAverage(measurements: section)
            averageHumidities.append(ChartableMeasurement(date: section.id, moisturePercentage: averages.moisturePercentage, soilTemperature: averages.soilTemperature))
        }
        
        return averageHumidities
    }
    
    func getChartData() -> [ChartableMeasurement] {
        switch preferences.chartScale {
        case .day, .week:
            return getHourlyMeasurements()
        case .month, .all:
            return getDailyAverages()
        }
    }
}

struct ChartableMeasurement: Identifiable {
    var date: Date
    var moisturePercentage: Float
    var soilTemperature: Float
    var id = UUID()
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

struct HumidityItemDaily_Previews: PreviewProvider {
    static var previews: some View {
        HumidityItem()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
