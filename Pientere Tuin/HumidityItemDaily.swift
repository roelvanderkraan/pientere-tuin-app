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
    
    @State var selectedDate: Date?
    @State var annotationPosition: AnnotationPosition = .automatic
    
    var body: some View {
        let data = getChartData()
        let average = getAverage(data: data)
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
                Text("\(average.moisturePercentage * 100, specifier: "%.1f")")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("%")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Chart(data) { dayAverage in
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
                    .accessibilityHidden(true)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .alignsMarkStylesWithPlotArea()
                if preferences.chartScale == .day {
                    PointMark(
                        x: .value("Day", dayAverage.date, unit: .hour),
                        y: .value("Moisture", dayAverage.moisturePercentage * 100)
                        
                    )
                    .annotation(
                        position: annotationPosition,
                        alignment: .center,
                        spacing: 0
                    ) {
                        if selectedDate == dayAverage.date {
                            MeasurementAnnotation(caption: Formatters.itemFormatter.string(from: dayAverage.date), value: dayAverage.moisturePercentage * 100, unit: "%", specifier: "%.1f")
                        }
                    }
                } else if preferences.chartScale == .week {
                    PointMark(
                        x: .value("Day", dayAverage.date, unit: .hour),
                        y: .value("Moisture", dayAverage.moisturePercentage * 100)
                        
                    )
                    .foregroundStyle(.clear)
                    .annotation(
                        position: annotationPosition,
                        alignment: .center,
                        spacing: 0
                    ) {
                        if selectedDate == dayAverage.date {
                            MeasurementAnnotation(caption: Formatters.itemFormatter.string(from: dayAverage.date), value: dayAverage.moisturePercentage * 100, unit: "%", specifier: "%.1f")
                        }
                    }
                } else {
                    PointMark(
                        x: .value("Day", dayAverage.date, unit: .hour),
                        y: .value("Moisture", dayAverage.moisturePercentage * 100)
                        
                    )
                    .annotation(
                        position: annotationPosition,
                        alignment: .center,
                        spacing: 0
                    ) {
                        if selectedDate == dayAverage.date {
                            MeasurementAnnotation(caption: Formatters.dateFormatter.string(from: dayAverage.date), value: dayAverage.moisturePercentage * 100, unit: "%", specifier: "%.1f")
                        }
                    }
                }
                
                
                if selectedDate == dayAverage.date {
                    RuleMark(
                        x: .value("Selected", dayAverage.date, unit: .hour)
                    )
                    .foregroundStyle(Color.gray.opacity(0.3))
                }
            }
            .chartForegroundStyleScale([
                "Moisture": .blue
            ])
            .chartLegend(.hidden)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(DragGesture().onChanged { value in
                            updateCursorPosition(at: value.location, geometry: geometry, proxy: proxy, data: data)
                        })
                        .onTapGesture { location in
                            updateCursorPosition(at: location, geometry: geometry, proxy: proxy, data: data)
                        }
                }
            }
            .padding([.trailing], 8)
            .chartYAxisLabel("%")
            .chartYScale(range: .plotDimension(startPadding:0, endPadding:30))
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
    
    func hourDate(of selectedDate: Date, data: [ChartableMeasurement]) -> Date? {
        var granularity: Calendar.Component = .hour
        if preferences.chartScale == .month || preferences.chartScale == .all {
            granularity = .day
        }
        let results = data.filter({ measurement in
            Calendar.current.isDate(measurement.date, equalTo: selectedDate, toGranularity: granularity)
        })
        return results.first?.date
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
    
    func getAverage(data: [ChartableMeasurement]) -> MeasurementAverage {
        let sumMoisture = data.reduce(0) {
            $0 + $1.moisturePercentage
        }
        let sumTemperature = data.reduce(0) {
            $0 + $1.soilTemperature
        }
        let count = Float(data.count)
        return MeasurementAverage(moisturePercentage: sumMoisture/count, soilTemperature: sumTemperature/count)
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
