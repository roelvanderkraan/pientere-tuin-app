//
//  HumidityItem.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 12/08/2023.
//

import SwiftUI
import Charts

struct HumidityHourlyItem: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.measuredAt, order: .reverse)],
        animation: .default)
    private var measurements: FetchedResults<MeasurementProjection>
        
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
//                Text("\(MeasurementStore.getAverage(measurements: measurements).averageValue, specifier: "%.1f")")
//                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
//                Text("%")
//                    .font(.system(.body, design: .rounded))
//                    .foregroundColor(.secondary)
            }
            Chart(measurements) { measurement in
                    LineMark(
                        x: .value("Hour", measurement.measuredAt ?? Date(), unit: .hour),
                        y: .value("Moisture", measurement.moisturePercentage * 100)
                        
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
            measurements.nsPredicate = .filter(key: "measuredAt", date: Date(), scale: newValue)
        }
        .onAppear {
            measurements.nsPredicate = .filter(key: "measuredAt", date: Date(), scale: preferences.chartScale)
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

struct HumidityItem_Previews: PreviewProvider {
    static var previews: some View {
        HumidityHourlyItem()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
