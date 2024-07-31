//
//  HumidityItem.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 12/08/2023.
//

import SwiftUI
import Charts
import SimpleAnalytics

struct MesurementChart: View {
    @SectionedFetchRequest<Date, MeasurementProjection>(
        sectionIdentifier: \.sectionMeasuredAt,
        sortDescriptors: [SortDescriptor(\.measuredAt, order: .reverse)]
    )
    private var sectionedMeasurements: SectionedFetchResults<Date, MeasurementProjection>
        
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var chartModel: ChartModel
    @ObservedObject var preferences = Preferences.shared
    
    @State var selectedDate: Date?
    @State var annotationPosition: AnnotationPosition = .automatic
    @State var chartTopPadding: CGFloat = 0
    var annotationHeight: CGFloat = 60
    
    var body: some View {
        let chartYScale = chartModel.getYScale()
        let dryValue = chartModel.getDryValue()
        VStack(alignment: .leading) {
            Picker("Chart scale", selection: $preferences.chartScale) {
                Text("Dag").tag(ChartScale.day)
                Text("Week").tag(ChartScale.week)
                Text("Maand").tag(ChartScale.month)
                Text("Alles").tag(ChartScale.all)
            }
            .pickerStyle(.segmented)
            .padding([.top, .bottom], 12)
            if selectedDate == nil {
                if let average = chartModel.chartAverage {
                    VStack(alignment: .leading) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(chartModel.typeIcon) Gemiddelde \(chartModel.typeText)")
                                .font(.system(.body, design: .default, weight: .medium))
                                .foregroundColor(chartModel.typeColor)
                            Spacer()
                        }
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(average.averageValue, specifier: "%.1f")")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            Text(chartModel.valueUnit)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(height: annotationHeight)
                }
            }
            Chart {
                if chartModel.chartType == .moisture, let dryValue = dryValue {
                    RuleMark(
                        y: .value("Droog", dryValue*100)
                    )
                    .foregroundStyle(Color.orange.opacity(0.3))
                    .annotation(
                        position: .top,
                        alignment: .trailing,
                        spacing: 0
                    ) {
                        Text("Droog")
                            .foregroundStyle(.orange)
                            .font(.footnote)

                    }
                }
                
                ForEach(chartModel.chartData) { dayAverage in
                    LineMark(
                        x: .value("Day", dayAverage.date, unit: .hour),
                        y: .value(chartModel.typeText, dayAverage.value)
                        
                    )
                    .foregroundStyle(chartModel.typeColor)
                    .accessibilityHidden(true)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    if preferences.chartScale != .week && preferences.chartScale != .all {
                        PointMark(
                            x: .value("Day", dayAverage.date, unit: .hour),
                            y: .value(chartModel.typeText, dayAverage.value)
                            
                        )
                        .foregroundStyle(chartModel.typeColor)
                    }
                    
                    if selectedDate == dayAverage.date {
                        if #available(iOS 17.0, *) {
                            RuleMark(
                                x: .value("Selected", dayAverage.date, unit: .hour)
                            )
                            .foregroundStyle(Color.gray.opacity(0.3))
                            .zIndex(-1)
                            .annotation(
                                position: .top,
                                spacing: 0,
                                overflowResolution: .init (
                                    x: .fit(to: .chart),
                                    y: .disabled
                                )
                            ) {
                                if selectedDate == dayAverage.date {
                                    switch preferences.chartScale {
                                    case .day, .week:
                                        MeasurementAnnotation(caption: Formatters.itemFormatter.string(from: dayAverage.date), value: dayAverage.value, unit: chartModel.valueUnit, specifier: chartModel.valueSpecifier)
                                    default:
                                        MeasurementAnnotation(caption: Formatters.dateFormatter.string(from: dayAverage.date), value: dayAverage.value, unit: chartModel.valueUnit, specifier: "%.1f")
                                    }
    
                                }
                            }
                        } else {
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
                                        MeasurementAnnotation(caption: Formatters.itemFormatter.string(from: dayAverage.date), value: dayAverage.value, unit: chartModel.valueUnit, specifier: chartModel.valueSpecifier)
                                            .frame(height: annotationHeight-8)
                                    default:
                                        MeasurementAnnotation(caption: Formatters.dateFormatter.string(from: dayAverage.date), value: dayAverage.value, unit: chartModel.valueUnit, specifier: "%.1f")
                                            .frame(height: annotationHeight-8)
                                    }
                                    
                                }
                            }
                        }
                    }
                }
            }
            .chartForegroundStyleScale([
                chartModel.typeText: chartModel.typeColor
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
            .padding(EdgeInsets(top: chartTopPadding, leading: 0, bottom: 16, trailing: 8))
            .chartYAxisLabel(chartModel.valueUnit)
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
                        if value.as(Date.self) != nil {
                            AxisValueLabel(format: .dateTime.weekday())
                        }
                        
                        AxisGridLine()
                        AxisTick()
                    }
                case .month:
                    AxisMarks(values: .stride(by: .day, count: 5)) { value in
                        if value.as(Date.self) != nil {
                            AxisValueLabel(format: .dateTime.day())
                        }
                        
                        AxisGridLine()
                        AxisTick()
                    }
                case .all:
                    AxisMarks(values: .stride(by: .month, count: 1)) { value in
                        if value.as(Date.self) != nil {
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
            SimpleAnalytics.shared.track(event: "chartscale-\(newValue)")
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
        if let (date, humidity) = proxy.value(at: location, as: (Date, Float).self) {
            debugPrint("Selected date: \(date), humidity: \(humidity)")
            selectedDate = hourDate(of: date, data: data)
            debugPrint("\(String(describing: selectedDate))")
        }

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

struct MeasurementChart_Previews: PreviewProvider {
    static var previews: some View {
        MesurementChart(chartModel: ChartModel(chartType: .temperature))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
