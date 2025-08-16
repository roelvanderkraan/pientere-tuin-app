//
//  MonthChart.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 12/08/2023.
//

import SwiftUI
import Charts
import SimpleAnalytics

struct MonthChart: View {
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
    
    private var chartYScale: ClosedRange<Float> {
        chartModel.getYScale()
    }
    
    private var dryValue: Float? {
        chartModel.getDryValue()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
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
                        x: .value("Day", dayAverage.date, unit: .day),
                        y: .value(chartModel.typeText, dayAverage.value)
                    )
                    .foregroundStyle(chartModel.typeColor)
                    .accessibilityHidden(true)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    if selectedDate == dayAverage.date {
                        if #available(iOS 17.0, *) {
                            RuleMark(
                                x: .value("Selected", dayAverage.date, unit: .day)
                            )
                            .foregroundStyle(Color.gray.opacity(0.3))
                            .zIndex(-1)
                            .annotation(
                                position: .top,
                                spacing: 0,
                                overflowResolution: .init(
                                    x: .fit(to: .chart),
                                    y: .disabled
                                )
                            ) {
                                annotationContent(for: dayAverage)
                            }
                        } else {
                            RuleMark(
                                x: .value("Selected", dayAverage.date, unit: .day)
                            )
                            .foregroundStyle(Color.gray.opacity(0.3))
                            .annotation(
                                position: annotationPosition,
                                alignment: .center,
                                spacing: 0
                            ) {
                                annotationContent(for: dayAverage)
                                    .frame(height: annotationHeight-8)
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
            .chartXScale(domain: chartModel.getXScale())
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 3600 * 24 * 30) // 30 days
            .chartScrollTargetBehavior(
                .valueAligned(
                    matching: DateComponents(day: 1),
                    majorAlignment: .matching(DateComponents(month: 1))
                )
            )
            .padding(EdgeInsets(top: chartTopPadding, leading: 0, bottom: 16, trailing: 8))
            .chartYAxisLabel(chartModel.valueUnit)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 5)) { value in
                    if value.as(Date.self) != nil {
                        AxisValueLabel(format: .dateTime.day())
                    }
                    AxisGridLine()
                    AxisTick()
                }
            }
        }
        .onAppear {
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
    
    @ViewBuilder
    private func annotationContent(for dayAverage: ChartableMeasurement) -> some View {
        MeasurementAnnotation(
            caption: Formatters.dateFormatter.string(from: dayAverage.date),
            value: dayAverage.value,
            unit: chartModel.valueUnit,
            specifier: "%.1f"
        )
    }
}

struct MonthChart_Previews: PreviewProvider {
    static var previews: some View {
        MonthChart(chartModel: ChartModel(chartType: .temperature))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
