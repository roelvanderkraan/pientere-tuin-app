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
    @State private var periodOffset: Int = 0
    @State var chartScrolledToDate: Date = Date()
    var annotationHeight: CGFloat = 60

    /// The length of the visible range for the current chart scale
    private var visibleLength: TimeInterval? {
        let calendar = Calendar.current
        let now = Date()
        switch preferences.chartScale {
        case .day:
            return 86_400 // 24h
        case .week:
            return 604_800 // 7d
        case .month:
            guard let monthInterval = calendar.dateInterval(of: .month, for: now) else { return nil }
            return monthInterval.duration
        case .all:
            return 31_536_000 // 1 year (365 * 24 * 60 * 60)
        }
    }

    /// Returns the available range of data in chartModel
    private var allDataRange: ClosedRange<Date>? {
        guard let minDate = chartModel.chartData.map(\.date).min(),
              let maxDate = chartModel.chartData.map(\.date).max() else {
            return nil
        }
        return minDate...maxDate
    }

    /// Computes the currently visible date range in the chart, clamped to the data's available range
    private var visibleChartRange: ClosedRange<Date>? {
        guard let visibleLength,
              let allRange = allDataRange else {
            return nil
        }
        let start = chartScrolledToDate
        let end = start.addingTimeInterval(visibleLength)
        // Clamp to data range
        let clampedStart = max(start, allRange.lowerBound)
        let clampedEnd = min(end, allRange.upperBound)
        // Only return if range is valid
        guard clampedStart <= clampedEnd else {
            return nil
        }
        return clampedStart...clampedEnd
    }
    
    var body: some View {
        let chartYScale = chartModel.getYScale()
        let dryValue = chartModel.getDryValue()
        VStack(alignment: .leading) {
            chartScalePicker
            if selectedDate == nil, let average = chartModel.chartAverage {
                ChartAverageHeader(
                    chartModel: chartModel,
                    average: average,
                    annotationHeight: annotationHeight,
                    visibleChartRange: visibleChartRange // <- Pass the range here
                )
                .id(chartScrolledToDate) // This forces it to update on scroll
            }
            ChartContent(
                chartModel: chartModel,
                preferences: preferences,
                selectedDate: $selectedDate,
                annotationPosition: $annotationPosition,
                annotationHeight: annotationHeight,
                chartYScale: chartYScale,
                dryValue: dryValue,
                periodOffset: $periodOffset,
                chartScrolledToDate: $chartScrolledToDate
            )
        }
        .onChange(of: preferences.chartScale) { newValue in
//            sectionedMeasurements.nsPredicate = .filter(key: "measuredAt", date: Date(), scale: newValue)
            chartModel.reloadData(measurements: sectionedMeasurements)
            selectedDate = nil
            SimpleAnalytics.shared.track(event: "chartscale-\(newValue)")
        }
        .onAppear {
//            sectionedMeasurements.nsPredicate = .filter(key: "measuredAt", date: Date(), scale: preferences.chartScale)
            chartModel.reloadData(measurements: sectionedMeasurements)
        }
        .onChange(of: selectedDate) { newValue in
            if newValue == nil {
                chartTopPadding = 0
            } else {
                chartTopPadding = annotationHeight + 8
            }
        }
    }
    
    private var chartScalePicker: some View {
        Picker("Chart scale", selection: $preferences.chartScale) {
            Text("Dag").tag(ChartScale.day)
            Text("Week").tag(ChartScale.week)
            Text("Maand").tag(ChartScale.month)
            Text("Alles").tag(ChartScale.all)
        }
        .pickerStyle(.segmented)
        .padding([.top, .bottom], 12)
    }
    
    private func periodBounds(for scale: ChartScale, reference: Date = Date(), offset: Int = 0) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let ref = calendar.date(byAdding: calendarComponent(for: scale), value: -offset, to: reference) ?? reference
        switch scale {
        case .day:
            let start = calendar.startOfDay(for: ref)
            let end = calendar.date(byAdding: .day, value: 1, to: start)?.addingTimeInterval(-1) ?? ref
            return start...end
        case .week:
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: ref)!
            return weekInterval.start...(weekInterval.end.addingTimeInterval(-1))
        case .month:
            let monthInterval = calendar.dateInterval(of: .month, for: ref)!
            return monthInterval.start...(monthInterval.end.addingTimeInterval(-1))
        case .all:
            if let minDate = chartModel.chartData.map(\.date).min(),
               let maxDate = chartModel.chartData.map(\.date).max() {
                return minDate...maxDate
            } else {
                let today = calendar.startOfDay(for: ref)
                return today...today
            }
        }
    }

    private func calendarComponent(for scale: ChartScale) -> Calendar.Component {
        switch scale {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        case .all: return .year // only used for offsetting the reference
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

// MARK: - ChartAverageHeader
private struct ChartAverageHeader: View {
    let chartModel: ChartModel
    let average: MeasurementAverage
    let annotationHeight: CGFloat
    let visibleChartRange: ClosedRange<Date>? // <-- added

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(chartModel.typeIcon) Gemiddelde \(chartModel.typeText)")
                    .font(.system(.body, design: .default, weight: .medium))
                    .foregroundColor(chartModel.typeColor)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("\(average.averageValue, specifier: "%.1f")")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(chartModel.valueUnit)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
            }
            if let range = visibleChartRange {
                Text("\(Formatters.dateFormatter.string(from: range.lowerBound)) – \(Formatters.dateFormatter.string(from: range.upperBound))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: annotationHeight)
    }
}

// MARK: - ChartContent
private struct ChartContent: View {
    @ObservedObject var chartModel: ChartModel
    @ObservedObject var preferences: Preferences
    @Binding var selectedDate: Date?
    @Binding var annotationPosition: AnnotationPosition
    var annotationHeight: CGFloat
    let chartYScale: ClosedRange<Float>
    let dryValue: Float?
    @Binding var periodOffset: Int
    @Binding var chartScrolledToDate: Date

    // Helper: Length in seconds for each scale
    private func visibleLength(for scale: ChartScale) -> TimeInterval? {
        let calendar = Calendar.current
        let now = Date()
        switch scale {
        case .day:
            return 86_400 // 24h
        case .week:
            return 604_800 // 7d
        case .month:
            guard let monthInterval = calendar.dateInterval(of: .month, for: now) else { return nil }
            return monthInterval.duration
        case .all:
            return 31_536_000 // 1 year (365 * 24 * 60 * 60)
        }
    }
    
    // Helper for scroll target "unit" (in seconds)
    private func scrollTargetUnit(for scale: ChartScale) -> Double {
        switch scale {
        case .day:
            return 3_600 // 1 hour
        case .week:
            return 86_400 // 1 day
        case .month:
            return 86_400 * 5 // 5 days
        case .all:
            return 31_536_000 // 1 year (365 * 24 * 60 * 60)
        }
    }
    
    private func allDataRange() -> ClosedRange<Date>? {
        guard let minDate = chartModel.chartData.map(\.date).min(),
              let maxDate = chartModel.chartData.map(\.date).max() else {
            return nil
        }
        return minDate...maxDate
    }
    
    var body: some View {
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
        .chartYAxisLabel(chartModel.valueUnit)
        .chartScrollableAxes(.horizontal)
        .chartScrollTargetBehavior(.valueAligned(unit: scrollTargetUnit(for: preferences.chartScale), majorAlignment: .page))
        .modifier(ChartVisibleDomainModifier(
            chartScale: preferences.chartScale,
            allRange: allDataRange(),
            visibleLength: visibleLength(for: preferences.chartScale)
        ))
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 8))
        .modifier(ChartXAxisModifier(chartScale: preferences.chartScale))
        .chartScrollPosition(initialX: Date())
        .chartScrollPosition(x: $chartScrolledToDate)
    }
}

// This modifier switches between .chartXVisibleDomain(length:) and .chartXVisibleDomain(_:) based on chartScale
private struct ChartVisibleDomainModifier: ViewModifier {
    let chartScale: ChartScale
    let allRange: ClosedRange<Date>?
    let visibleLength: TimeInterval?
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if let visibleLength {
            content.chartXVisibleDomain(length: visibleLength)
        } else {
            content
        }
    }
}

// MARK: - ChartXAxisModifier
private struct ChartXAxisModifier: ViewModifier {
    let chartScale: ChartScale
    
    func body(content: Content) -> some View {
        content.chartXAxis {
            switch chartScale {
            case .day:
                AxisMarks(values: .stride(by: .hour, count: 4)) { value in
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
                AxisMarks(values: .stride(by: .year, count: 1)) { value in
                    if value.as(Date.self) != nil {
                        AxisValueLabel(format: .dateTime.year())
                    }
                    AxisGridLine()
                    AxisTick()
                }
            }
        }
    }
}

struct MeasurementChart_Previews: PreviewProvider {
    static var previews: some View {
        MesurementChart(chartModel: ChartModel(chartType: .temperature))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
