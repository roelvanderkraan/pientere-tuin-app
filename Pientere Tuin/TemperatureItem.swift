//
//  TemperatureItem.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 12/08/2023.
//

import SwiftUI
import Charts

struct TemperatureItem: View {
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
                Text("\(Image(systemName: "thermometer.medium")) Average soil temperature")
                    .font(.system(.body, design: .default, weight: .medium))
                    .foregroundColor(.green)
                Spacer()
            }
            HStack(alignment: .firstTextBaseline) {
                Text("\(MeasurementStore.getAverage(measurements: measurements).soilTemperature, specifier: "%.1f")")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("°C")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Chart {
                ForEach (measurements) { measurement in
                    if measurement.temperatureCelcius != 0.0 {
                        LineMark(
                            x: .value("Month", measurement.measuredAt ?? Date()),
                            y: .value("Temperature", measurement.temperatureCelcius)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.blue, .yellow, .red],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .alignsMarkStylesWithPlotArea()
                    }
                }
            }
            .chartForegroundStyleScale([
                "Temperature": .green
            ])
            .chartLegend(.hidden)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 8))
            .chartYAxisLabel("°C")
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3))
                AxisMarks(
                    values: .automatic(desiredCount: 3)
                ) {
                    AxisGridLine()
                }
            }
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
        .onChange(of: Preferences.shared.chartScale) { newValue in
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

struct TemperatureItem_Previews: PreviewProvider {
    static var previews: some View {
        TemperatureItem()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
