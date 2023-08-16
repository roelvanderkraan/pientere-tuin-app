//
//  HumidityItem.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 12/08/2023.
//

import SwiftUI
import Charts

struct HumidityItem: View {
    @FetchRequest var measurements: FetchedResults<MeasurementProjection>
        
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var scale: ChartScale
    
    var body: some View {
        VStack {
            Chart {
                ForEach (measurements) { measurement in
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
                    .alignsMarkStylesWithPlotArea()
                }
            }
            .chartForegroundStyleScale([
                "Moisture": .blue
            ])
            .chartLegend(.hidden)
            .padding([.trailing], 8)
            .chartYAxisLabel("%")
            .chartXAxis {
                switch scale {
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
        HumidityItem(
            measurements: FetchRequest<MeasurementProjection>(
                sortDescriptors: [NSSortDescriptor(keyPath: \MeasurementProjection.measuredAt, ascending: false)],
                predicate: .filter(key: "measuredAt", date: Date(), scale: .month)
            ), scale: .constant(.month)
        )
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
