//
//  HumidityItem.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 12/08/2023.
//

import SwiftUI
import Charts

struct HumidityDailyItem: View {
    var chartType: ChartType
    
    @SectionedFetchRequest<Date, MeasurementProjection>(
        sectionIdentifier: \.sectionMeasuredAt,
        sortDescriptors: [SortDescriptor(\.measuredAt, order: .reverse)]
    )
    private var sectionedMeasurements: SectionedFetchResults<Date, MeasurementProjection>
        
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject private var chartModel = ChartModel()
    @ObservedObject private var preferences = Preferences.shared
    
    @State private var selectedDate: Date?
    @State private var annotationPosition: AnnotationPosition = .automatic
    @State private var chartTopPadding: CGFloat = 0
    private var annotationHeight: CGFloat = 60

    init(chartType: ChartType) {
        self.chartType = chartType
    }
    
    var body: some View {
        let chartYScale = chartModel.getYScale()
        let dryValue = chartModel.getDryValue()
        VStack(alignment: .leading) {
            Picker("Chart scale", selection: $preferences.chartScale) {
                Text("D").tag(ChartScale.day)
                Text("W").tag(ChartScale.week)
                Text("M").tag(ChartScale.month)
                Text("All").tag(ChartScale.all)
            }
            .pickerStyle(.segmented)
            if selectedDate == nil {
                if let average = chartModel.chartAverage {
                    VStack(alignment: .leading) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(Image(systemName: "drop.fill")) Average soil humidity")
                                .font(.system(.body, design: .default, weight: .medium))
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(average.moisturePercentage * 100, specifier: "%.1f")")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            Text("%")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(height: annotationHeight)
                }
            }
            Chart {
                if let dryValue = dryValue {
                    RuleMark(
                        y: .value("Dry", dryValue*100)
                    )
                    .foregroundStyle(Color.orange.opacity(0.3))
                    .annotation(
                        position: .top,
                        alignment: .trailing,
                        spacing: 0
                    ) {
                        Text("Dry")
                            .foregroundStyle(.orange)
                            .font(.footnote)

                    }
                }
                
                ForEach(chartModel.chartData) { dayAverage in
                    LineMark(
                        x: .value("Day", dayAverage.date, unit: .hour),
                        y: .value("Moisture", dayAverage.moisturePercentage * 100)
                        
                    )
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    if preferences.chartScale != .week {
                        PointMark(
                            x: .value("Day", dayAverage.date, unit: .hour),
                            y: .value("Moisture", dayAverage.moisturePercentage * 100)
                            
                        )
                    }
                    
                    if selectedDate == dayAverage.date {
                        RuleMark(
                            x: .value("Selected", dayAverage.date, unit: .hour)
                        )
                        .foregroundStyle(Color.gray.opacity(0.3))
                        .annotation(
                            position: annotationPosition,
                            alignment: .center,
                            spacing: 0
                        ) {
                            if selectedDate == dayAverage.date {
                                switch preferences.chartScale {
                                case .day, .week:
                                    MeasurementAnnotation(caption: Formatters.itemFormatter.string(from: dayAverage.date), value: dayAverage.moisturePercentage * 100, unit: "%", specifier: "%.1f")
                                        .frame(height: annotationHeight-8)
                                default:
                                    MeasurementAnnotation(caption: Formatters.dateFormatter.string(from: dayAverage.date), value: dayAverage.moisturePercentage * 100, unit: "%", specifier: "%.1f")
                                        .frame(height: annotationHeight-8)
                                }
                                
                            }
                        }
                    }
                }
            }
            .chartForegroundStyleScale([
                "Moisture": .blue
            ])
            .chartLegend(.hidden)
            .chartYScale(domain: chartYScale)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(DragGesture().onChanged { value in
                            updateCursorPosition(at: value.location, geometry: geometry, proxy: proxy, data: chartModel.chartData)
                        })
                        .onTapGesture { location in
                            if selectedDate == nil {
                                updateCursorPosition(at: location, geometry: geometry, proxy: proxy, data: chartModel.chartData)
                            } else {
                                selectedDate = nil
                            }
                        }
                }
            }
            .padding(EdgeInsets(top: chartTopPadding, leading: 0, bottom: 0, trailing: 8))
            .chartYAxisLabel("%")
//            .chartYScale(range: .plotDimension(startPadding:0, endPadding:30))
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
        .onChange(of: preferences.chartScale) { newValue in
            sectionedMeasurements.nsPredicate = .filter(key: "measuredAt", date: Date(), scale: newValue)
            chartModel.reloadData(measurements: sectionedMeasurements)
            selectedDate = nil
        }
        .onAppear {
            sectionedMeasurements.nsPredicate = .filter(key: "measuredAt", date: Date(), scale: preferences.chartScale)
            chartModel.reloadData(measurements: sectionedMeasurements)
        }
        .onChange(of: selectedDate) { newValue in
            if newValue == nil {
                chartTopPadding = 0
            } else {
                chartTopPadding = annotationHeight+8
            }
        }
    }
    
    func updateCursorPosition(at: CGPoint, geometry: GeometryProxy, proxy: ChartProxy, data: [ChartableMeasurement]) {
        let origin = geometry[proxy.plotAreaFrame].origin
        let width = geometry[proxy.plotAreaFrame].width
        let annotationWidth = 60.0
        let location = CGPoint(
            x: at.x - origin.x,
            y: at.y - origin.y
        )
        let (date, humidity) = proxy.value(at: location, as: (Date, Float).self)!
        debugPrint("Selected date: \(date ?? Date()), humidity: \(humidity)")
        selectedDate = hourDate(of: date, data: data)
        debugPrint("\(selectedDate)")

        if location.x < annotationWidth {
            annotationPosition = .topTrailing
        } else if location.x > width - annotationWidth {
            annotationPosition = .topLeading
        } else {
            annotationPosition = .top
        }
      }
    
    private func hourDate(of selectedDate: Date, data: [ChartableMeasurement]) -> Date? {
        var granularity: Calendar.Component = .hour
        if preferences.chartScale == .month || preferences.chartScale == .all {
            granularity = .day
        }
        let results = data.filter({ measurement in
            Calendar.current.isDate(measurement.date, equalTo: selectedDate, toGranularity: granularity)
        })
        return results.first?.date
    }
}

struct ChartableMeasurement: Identifiable {
    var date: Date
    var moisturePercentage: Float
    var temperatureCelcius: Float
    var id = UUID()
}

enum ChartType {
    case moisture
    case temperature
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

struct HumidityItemDaily_Previews: PreviewProvider {
    static var previews: some View {
        HumidityDailyItem(chartType: .moisture)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
