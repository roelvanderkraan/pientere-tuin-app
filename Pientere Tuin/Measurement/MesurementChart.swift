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
        sortDescriptors: [SortDescriptor(\.measuredAt, order: .reverse)],
        predicate: NSPredicate.recentData(key: "measuredAt", monthsBack: 6)
    )
    private var sectionedMeasurements: SectionedFetchResults<Date, MeasurementProjection>
        
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var chartModel: ChartModel
    @ObservedObject var preferences = Preferences.shared
    
    @State var selectedDate: Date?
    @State var annotationPosition: AnnotationPosition = .automatic
    @State private var periodOffset: Int = 0
    @State var chartScrolledToDate: Date = Date()
    @State private var isScrolledAwayFromPresent: Bool = false
    @State private var scrollDebounceTask: Task<Void, Never>?
    @State private var loadedMonthsBack: Int = 6 // Track how far back we've loaded
    @State private var isLoadingMore: Bool = false // Prevent reload loops
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
        case .year:
            return 31_536_000 // 1 year (365 * 24 * 60 * 60)
        }
    }

    /// Returns the available range of data in chartModel (cached in ChartModel)
    private var allDataRange: ClosedRange<Date>? {
        chartModel.cachedDataRange
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
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                chartScalePicker
                
                ZStack(alignment: .topLeading) {
                    // Chart - always present with fixed layout
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
                    .frame(height: 280)
                    
                    // Header overlay - always present, just hidden when selecting
                    if let average = chartModel.chartAverage {
                        VStack(alignment: .leading, spacing: 0) {
                            ChartAverageHeader(
                                chartModel: chartModel,
                                average: average,
                                annotationHeight: annotationHeight,
                                visibleChartRange: visibleChartRange
                            )
                            .opacity(selectedDate == nil ? 1 : 0)
                            .allowsHitTesting(selectedDate == nil)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            // Back to Present button
            if isScrolledAwayFromPresent {
                Button {
                    withAnimation {
                        chartScrolledToDate = getInitialScrollPosition()
                    }
                    SimpleAnalytics.shared.track(event: "chart-back-to-present")
                } label: {
                    Label("Nu", systemImage: "arrow.forward.to.line")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
        .onChange(of: preferences.chartScale) { newValue in
//            sectionedMeasurements.nsPredicate = .filter(key: "measuredAt", date: Date(), scale: newValue)
            chartModel.reloadData(measurements: sectionedMeasurements)
            selectedDate = nil
            // Reset to latest measurement when scale changes (snapped to period start)
            chartScrolledToDate = getInitialScrollPosition()
            SimpleAnalytics.shared.track(event: "chartscale-\(newValue)")
        }
        .onAppear {
            chartModel.reloadData(measurements: sectionedMeasurements)
            // Initialize scroll to latest measurement
            chartScrolledToDate = getInitialScrollPosition()
        }
        .onChange(of: sectionedMeasurements.count) { _ in
            // Reload chart data when fetch results change (progressive loading)
            if isLoadingMore {
                chartModel.reloadData(measurements: sectionedMeasurements)
                isLoadingMore = false
            }
        }
        .onChange(of: chartScrolledToDate) { newValue in
            // Check if scrolled away from latest data
            if let latestDate = chartModel.cachedDataRange?.upperBound {
                let threshold: TimeInterval = 3600 // 1 hour threshold
                isScrolledAwayFromPresent = newValue.addingTimeInterval(threshold) < latestDate
            }
            
            // Progressive loading: Check if we need to load more historical data
            checkAndExpandDataRange(scrolledTo: newValue)
        }
    }
    
    /// Checks if the user is scrolling close to the oldest loaded data and expands the fetch range
    private func checkAndExpandDataRange(scrolledTo date: Date) {
        // Don't trigger if already loading
        guard !isLoadingMore else { return }
        
        guard let oldestLoadedDate = chartModel.cachedDataRange?.lowerBound else { return }
        
        let calendar = Calendar.current
        let threshold: TimeInterval
        
        // Set threshold based on chart scale
        switch preferences.chartScale {
        case .day:
            threshold = 86_400 * 7 // 7 days
        case .week:
            threshold = 604_800 * 4 // 4 weeks
        case .month:
            threshold = 2_592_000 * 2 // 2 months
        case .year:
            threshold = 2_592_000 * 6 // 6 months
        }
        
        // Calculate distance from scrolled position to oldest loaded data
        let distanceToOldest = date.timeIntervalSince(oldestLoadedDate)
        
        // Trigger when scrolled date is within threshold of the oldest date
        if distanceToOldest > 0 && distanceToOldest < threshold && loadedMonthsBack < 36 { // Max 3 years
            isLoadingMore = true
            
            // Expand by 6 more months
            loadedMonthsBack += 6
            let newStartDate = calendar.date(byAdding: .month, value: -loadedMonthsBack, to: Date()) ?? Date()
            
            // Update the fetch request predicate
            sectionedMeasurements.nsPredicate = NSPredicate.dateRange(
                key: "measuredAt",
                from: newStartDate,
                to: Date()
            )
        }
    }
    
    private var chartScalePicker: some View {
        Picker("Chart scale", selection: $preferences.chartScale) {
            Text("Dag").tag(ChartScale.day)
            Text("Week").tag(ChartScale.week)
            Text("Maand").tag(ChartScale.month)
            Text("Jaar").tag(ChartScale.year)
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
        case .year:
            let yearInterval = calendar.dateInterval(of: .year, for: ref)!
            return yearInterval.start...(yearInterval.end.addingTimeInterval(-1))
        }
    }

    private func calendarComponent(for scale: ChartScale) -> Calendar.Component {
        switch scale {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        case .year: return .year
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
            selectedDate = hourDate(of: date, data: data)
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
        if preferences.chartScale == .month || preferences.chartScale == .year {
            granularity = .day
        }
        let results = data.filter({ measurement in
            Calendar.current.isDate(measurement.date, equalTo: selectedDate, toGranularity: granularity)
        })
        return results.first?.date
    }
    
    // Snaps a date to the start of its calendar period
    private func snapToStartOfPeriod(_ date: Date, scale: ChartScale) -> Date {
        let calendar = Calendar.current
        switch scale {
        case .day:
            return calendar.startOfDay(for: date)
        case .week:
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
                return date
            }
            return weekStart
        case .month:
            guard let monthStart = calendar.dateInterval(of: .month, for: date)?.start else {
                return date
            }
            return monthStart
        case .year:
            let year = calendar.component(.year, from: date)
            return calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? date
        }
    }
    
    // Gets the appropriate initial scroll position
    // Returns the latest date WITHOUT snapping to allow viewing current incomplete periods
    private func getInitialScrollPosition() -> Date {
        // Optimized: direct access to last element
        return chartModel.chartData.last?.date ?? Date()
    }
    
    // Gets the calendar granularity for a given chart scale
    private func getPeriodGranularity(for scale: ChartScale) -> Calendar.Component {
        switch scale {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        case .year: return .year
        }
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
        case .year:
            return 31_536_000 // 1 year (365 * 24 * 60 * 60)
        }
    }
    
    // Helper for scroll target "unit" (in seconds) - used for fine-grained snapping
    private func scrollTargetUnit(for scale: ChartScale) -> Double {
        switch scale {
        case .day:
            return 3_600 // 1 hour
        case .week:
            return 86_400 // 1 day
        case .month:
            return 86_400 // 1 day (snap to days within months)
        case .year:
            return 2_592_000 // ~30 days (1 month approximation)
        }
    }
    
    private func allDataRange() -> ClosedRange<Date>? {
        chartModel.cachedDataRange
    }
    
    var body: some View {
        Chart {
            // Dry threshold line (if applicable)
            if chartModel.chartType == .moisture, let dryValue = dryValue {
                RuleMark(y: .value("Droog", dryValue*100))
                    .foregroundStyle(Color.orange.opacity(0.3))
                    .annotation(position: .top, alignment: .trailing, spacing: 0) {
                        Text("Droog")
                            .foregroundStyle(.orange)
                            .font(.footnote)
                    }
            }
            
            // Main data line and points
            ForEach(chartModel.chartData) { measurement in
                LineMark(
                    x: .value("Time", measurement.date, unit: .hour),
                    y: .value(chartModel.typeText, measurement.value)
                )
                .foregroundStyle(chartModel.typeColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                // Show points for day and month views only
                if preferences.chartScale == .day || preferences.chartScale == .month {
                    PointMark(
                        x: .value("Time", measurement.date, unit: .hour),
                        y: .value(chartModel.typeText, measurement.value)
                    )
                    .foregroundStyle(chartModel.typeColor)
                }
            }
            
            // Selection indicator (outside ForEach for performance)
            if let selectedDate,
               let selectedValue = chartModel.chartData.first(where: { $0.date == selectedDate })?.value {
                RuleMark(x: .value("Selected", selectedDate, unit: .hour))
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .annotation(position: .top, spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(selectedValue, specifier: chartModel.valueSpecifier)")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                Text(chartModel.valueUnit)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            Text(formatDate(selectedDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color(uiColor: .systemBackground).opacity(0.9))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    }
            }
        }
        .chartForegroundStyleScale([
            chartModel.typeText: chartModel.typeColor
        ])
        .chartLegend(.hidden)
        .chartYScale(domain: chartYScale)
        .chartYAxisLabel(chartModel.valueUnit)
        .chartPlotStyle { plotArea in
            plotArea.padding(.top, 80)
        }
        .chartScrollableAxes(.horizontal)
        .chartScrollTargetBehavior(.valueAligned(unit: scrollTargetUnit(for: preferences.chartScale), majorAlignment: .page))
        .modifier(ChartVisibleDomainModifier(
            chartScale: preferences.chartScale,
            allRange: allDataRange(),
            visibleLength: visibleLength(for: preferences.chartScale)
        ))
        .padding(EdgeInsets(top: 8, leading: 0, bottom: 16, trailing: 8))
        .modifier(ChartXAxisModifier(chartScale: preferences.chartScale))
        .chartScrollPosition(x: $chartScrolledToDate)
        .chartXSelection(value: $selectedDate)
        .onChange(of: selectedDate) { newValue in
            // Snap selected date to nearest data point
            if let tappedDate = newValue {
                selectedDate = findNearestDataPoint(to: tappedDate)
            }
        }
    }
    
    // Find the nearest data point to the tapped date
    private func findNearestDataPoint(to date: Date) -> Date? {
        let granularity: Calendar.Component = (preferences.chartScale == .month || preferences.chartScale == .year) ? .day : .hour
        
        // Find data point matching the tapped date at the appropriate granularity
        let matching = chartModel.chartData.first { measurement in
            Calendar.current.isDate(measurement.date, equalTo: date, toGranularity: granularity)
        }
        
        return matching?.date
    }
    
    // Format date for annotation based on chart scale
    private func formatDate(_ date: Date) -> String {
        switch preferences.chartScale {
        case .day, .week:
            return Formatters.itemFormatter.string(from: date)
        default:
            return Formatters.dateFormatter.string(from: date)
        }
    }
}

// This modifier sets the visible domain and scroll bounds for the chart
private struct ChartVisibleDomainModifier: ViewModifier {
    let chartScale: ChartScale
    let allRange: ClosedRange<Date>?
    let visibleLength: TimeInterval?
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if let allRange {
            if let visibleLength {
                content
                    .chartXVisibleDomain(length: visibleLength)
                    .chartXScale(domain: allRange)
            } else {
                content
                    .chartXScale(domain: allRange)
            }
        } else if let visibleLength {
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
            case .year:
                AxisMarks(values: .stride(by: .month, count: 1)) { value in
                    if value.as(Date.self) != nil {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
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
