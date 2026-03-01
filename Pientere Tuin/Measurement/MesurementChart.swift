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
    @State private var loadedMonthsBack: Int = 6
    @State private var isLoadingMore: Bool = false
    @State private var scrollToLatestTrigger: Int = 0

    /// Returns the available range of data in chartModel (cached in ChartModel)
    private var allDataRange: ClosedRange<Date>? {
        chartModel.cachedDataRange
    }

    var body: some View {
        let chartYScale = chartModel.getYScale()
        let dryValue = chartModel.getDryValue()
        VStack(alignment: .leading, spacing: 8) {
            chartScalePicker

            ChartContent(
                chartData: chartModel.chartData,
                chartType: chartModel.chartType,
                typeIcon: chartModel.typeIcon,
                typeText: chartModel.typeText,
                typeColor: chartModel.typeColor,
                valueSpecifier: chartModel.valueSpecifier,
                valueUnit: chartModel.valueUnit,
                average: chartModel.chartAverage,
                chartYScale: chartYScale,
                dryValue: dryValue,
                chartScale: preferences.chartScale,
                allDataRange: allDataRange,
                selectedDate: $selectedDate,
                initialScrollDate: chartModel.chartData.last?.date ?? Date(),
                scrollToLatestTrigger: scrollToLatestTrigger,
                onScrolledNearOldest: { date in
                    checkAndExpandDataRange(scrolledTo: date)
                }
            )
            .frame(height: 280)
        }
        .onChange(of: preferences.chartScale) { newValue in
            chartModel.reloadData(measurements: sectionedMeasurements)
            selectedDate = nil
            scrollToLatestTrigger += 1
            SimpleAnalytics.shared.track(event: "chartscale-\(newValue)")
        }
        .onAppear {
            chartModel.reloadData(measurements: sectionedMeasurements)
        }
        .onChange(of: sectionedMeasurements.count) { _ in
            // Reload chart data whenever a section (day) is added or removed.
            // ChartModel's cache invalidates automatically when the section count changes.
            chartModel.reloadData(measurements: sectionedMeasurements)
            isLoadingMore = false
        }
    }

    /// Checks if the user is scrolling close to the oldest loaded data and expands the fetch range
    private func checkAndExpandDataRange(scrolledTo date: Date) {
        guard !isLoadingMore else { return }
        guard let oldestLoadedDate = chartModel.cachedDataRange?.lowerBound else { return }

        let threshold: TimeInterval
        switch preferences.chartScale {
        case .day:   threshold = 86_400 * 7      // 7 days
        case .week:  threshold = 604_800 * 4     // 4 weeks
        case .month: threshold = 2_592_000 * 2   // 2 months
        case .year:  threshold = 2_592_000 * 6   // 6 months
        }

        let distanceToOldest = date.timeIntervalSince(oldestLoadedDate)
        guard distanceToOldest > 0 && distanceToOldest < threshold && loadedMonthsBack < 36 else { return }

        isLoadingMore = true
        loadedMonthsBack += 6
        let newStartDate = Calendar.current.date(byAdding: .month, value: -loadedMonthsBack, to: Date()) ?? Date()
        sectionedMeasurements.nsPredicate = NSPredicate.dateRange(
            key: "measuredAt",
            from: newStartDate,
            to: Date()
        )
    }

    private var chartScalePicker: some View {
        // Note: "Dag" (day) scale is hidden from the picker until scroll performance is resolved.
        // The ChartScale.day code path is fully intact — remove this comment and restore the tag to re-enable it.
        Picker("Chart scale", selection: $preferences.chartScale) {
            Text("Week").tag(ChartScale.week)
            Text("Maand").tag(ChartScale.month)
            Text("Jaar").tag(ChartScale.year)
        }
        .pickerStyle(.segmented)
        .padding([.top, .bottom], 12)
    }
}

// MARK: - ChartAverageHeader
private struct ChartAverageHeader: View {
    let typeIcon: Image
    let typeText: String
    let typeColor: Color
    let valueUnit: String
    let average: MeasurementAverage
    let visibleChartRange: ClosedRange<Date>?

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(typeIcon) Gemiddelde \(typeText)")
                    .font(.system(.body, design: .default, weight: .medium))
                    .foregroundColor(typeColor)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("\(average.averageValue, specifier: "%.1f")")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(valueUnit)
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
// Receives all data as value types so SwiftUI can efficiently diff renders.
// No @ObservedObject here — the parent drives updates by passing new values.
// All scroll-driven state lives here so MesurementChart.body stays idle during scroll.
private struct ChartContent: View {
    let chartData: [ChartableMeasurement]
    let chartType: ChartType
    let typeIcon: Image
    let typeText: String
    let typeColor: Color
    let valueSpecifier: String
    let valueUnit: String
    let average: MeasurementAverage?
    let chartYScale: ClosedRange<Float>
    let dryValue: Float?
    let chartScale: ChartScale
    let allDataRange: ClosedRange<Date>?
    @Binding var selectedDate: Date?
    let initialScrollDate: Date
    let scrollToLatestTrigger: Int
    let onScrolledNearOldest: (Date) -> Void

    // Scroll-driven state lives here — changes don't bubble up to MesurementChart
    @State private var chartScrolledToDate: Date = Date()
    @State private var isScrolledAwayFromPresent: Bool = false
    @State private var scrollDebounceTask: Task<Void, Never>?
    @State private var hasSetInitialPosition: Bool = false

    // Length in seconds for the visible window at each scale
    private func visibleLength(for scale: ChartScale) -> TimeInterval? {
        let calendar = Calendar.current
        let now = Date()
        switch scale {
        case .day:   return 86_400
        case .week:  return 604_800
        case .month:
            guard let monthInterval = calendar.dateInterval(of: .month, for: now) else { return nil }
            return monthInterval.duration
        case .year:  return 31_536_000
        }
    }

    // Snapping unit in seconds — controls fine-grained scroll alignment
    private func scrollTargetUnit(for scale: ChartScale) -> Double {
        switch scale {
        case .day:   return 3_600    // 1 hour
        case .week:  return 86_400   // 1 day
        case .month: return 86_400   // 1 day
        case .year:  return 2_592_000 // ~30 days
        }
    }

    /// Computes the currently visible date range in the chart, clamped to the data's available range
    private var visibleChartRange: ClosedRange<Date>? {
        guard let length = visibleLength(for: chartScale),
              let allRange = allDataRange else { return nil }
        let start = chartScrolledToDate
        let end = start.addingTimeInterval(length)
        let clampedStart = max(start, allRange.lowerBound)
        let clampedEnd = min(end, allRange.upperBound)
        guard clampedStart <= clampedEnd else { return nil }
        return clampedStart...clampedEnd
    }

    private func getInitialScrollPosition() -> Date {
        allDataRange?.upperBound ?? Date()
    }

    // PointPlot draws individual symbols — each one is a separate GPU draw call.
    // Only use for month scale (~180 points). Day scale uses line only (like Health app).
    // chartData stays full so the line has no gaps.
    private var visiblePointData: [ChartableMeasurement] {
        guard let length = visibleLength(for: chartScale) else { return chartData }
        let buffer = length * 2
        let windowStart = chartScrolledToDate.addingTimeInterval(-buffer)
        let windowEnd   = chartScrolledToDate.addingTimeInterval(length + buffer)
        return chartData.filter { $0.date >= windowStart && $0.date <= windowEnd }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack(alignment: .topLeading) {
                Chart {
                    // Dry threshold line (if applicable)
                    if chartType == .moisture, let dryValue = dryValue {
                        RuleMark(y: .value("Droog", dryValue * 100))
                            .foregroundStyle(Color.orange.opacity(0.3))
                            .annotation(position: .top, alignment: .trailing, spacing: 0) {
                                Text("Droog")
                                    .foregroundStyle(.orange)
                                    .font(.footnote)
                            }
                    }

                    // Main data line.
                    // LinePlot draws a single connected path — efficient even with thousands of points.
                    LinePlot(
                        chartData,
                        x: .value("Time", \.date),
                        y: .value(typeText, \.value)
                    )
                    .foregroundStyle(typeColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    // PointPlot only for month scale (~180 points, not per-frame issue).
                    // Day scale omits points entirely to eliminate per-frame GPU draw calls.
                    if chartScale == .month {
                        PointPlot(
                            visiblePointData,
                            x: .value("Time", \.date),
                            y: .value(typeText, \.value)
                        )
                        .foregroundStyle(typeColor)
                    }

                    // Selection indicator
                    if let selectedDate,
                       let selectedValue = chartData.first(where: { $0.date == selectedDate })?.value {
                        RuleMark(x: .value("Selected", selectedDate, unit: .hour))
                            .foregroundStyle(Color.gray.opacity(0.3))
                            .annotation(position: .automatic, spacing: 0) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text("\(selectedValue, specifier: valueSpecifier)")
                                            .font(.system(.title, design: .rounded, weight: .bold))
                                        Text(valueUnit)
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
                .chartForegroundStyleScale([typeText: typeColor])
                .chartLegend(.hidden)
                .chartYScale(domain: chartYScale)
                .chartYAxisLabel(valueUnit)
                .chartPlotStyle { plotArea in
                    plotArea.padding(.top, 80)
                }
                .chartScrollableAxes(.horizontal)
                .chartScrollTargetBehavior(.valueAligned(unit: scrollTargetUnit(for: chartScale), majorAlignment: .page))
                .modifier(ChartVisibleDomainModifier(
                    chartScale: chartScale,
                    allRange: allDataRange,
                    visibleLength: visibleLength(for: chartScale)
                ))
                .padding(EdgeInsets(top: 8, leading: 0, bottom: 16, trailing: 8))
                .modifier(ChartXAxisModifier(chartScale: chartScale))
                .chartScrollPosition(x: $chartScrolledToDate)
                .chartXSelection(value: $selectedDate)
                .onChange(of: selectedDate) { newValue in
                    if let tappedDate = newValue {
                        selectedDate = findNearestDataPoint(to: tappedDate)
                    }
                }
                .onAppear {
                    guard !hasSetInitialPosition else { return }
                    chartScrolledToDate = initialScrollDate
                    hasSetInitialPosition = true
                }
                .onChange(of: scrollToLatestTrigger) { _ in
                    withAnimation { chartScrolledToDate = getInitialScrollPosition() }
                }
                .onChange(of: chartScrolledToDate) { newValue in
                    // Immediate: cheap check for "back to present" button visibility
                    if let latestDate = allDataRange?.upperBound {
                        let threshold: TimeInterval = 3600 // 1 hour
                        isScrolledAwayFromPresent = newValue.addingTimeInterval(threshold) < latestDate
                    }

                    // Debounced: expanding the fetch predicate is expensive — skip frames that
                    // arrive during active scrolling and only act after the user pauses.
                    scrollDebounceTask?.cancel()
                    scrollDebounceTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 250_000_000) // 250 ms
                        guard !Task.isCancelled else { return }
                        onScrolledNearOldest(newValue)
                    }
                }

                // Header overlay — lives inside ChartContent so it updates with scroll state
                if let average {
                    VStack(alignment: .leading, spacing: 0) {
                        ChartAverageHeader(
                            typeIcon: typeIcon,
                            typeText: typeText,
                            typeColor: typeColor,
                            valueUnit: valueUnit,
                            average: average,
                            visibleChartRange: visibleChartRange
                        )
                        .opacity(selectedDate == nil ? 1 : 0)
                        .allowsHitTesting(selectedDate == nil)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Back to Present button — lives here, driven by local isScrolledAwayFromPresent
            if isScrolledAwayFromPresent {
                Button {
                    withAnimation { chartScrolledToDate = getInitialScrollPosition() }
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
    }

    // Find the data point whose date matches the tapped date at the appropriate granularity
    private func findNearestDataPoint(to date: Date) -> Date? {
        let granularity: Calendar.Component = (chartScale == .month || chartScale == .year) ? .day : .hour
        return chartData.first { measurement in
            Calendar.current.isDate(measurement.date, equalTo: date, toGranularity: granularity)
        }?.date
    }

    // Format date for the selection annotation based on chart scale
    private func formatDate(_ date: Date) -> String {
        switch chartScale {
        case .day, .week:
            return Formatters.itemFormatter.string(from: date)
        default:
            return Formatters.dateFormatter.string(from: date)
        }
    }
}

// MARK: - ChartVisibleDomainModifier
// Sets the visible domain and scroll bounds for the chart
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
