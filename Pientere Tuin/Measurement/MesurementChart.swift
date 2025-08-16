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
    @ObservedObject var chartModel: ChartModel
    @ObservedObject var preferences = Preferences.shared
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker("Chart scale", selection: $preferences.chartScale) {
                Text("Dag").tag(ChartScale.day)
                Text("Week").tag(ChartScale.week)
                Text("Maand").tag(ChartScale.month)
                Text("Alles").tag(ChartScale.all)
            }
            .pickerStyle(.segmented)
            .padding([.top, .bottom], 12)
            
            switch preferences.chartScale {
            case .day:
                DayChart(chartModel: chartModel, preferences: preferences)
            case .week:
                WeekChart(chartModel: chartModel, preferences: preferences)
            case .month:
                MonthChart(chartModel: chartModel, preferences: preferences)
            case .all:
                AllChart(chartModel: chartModel, preferences: preferences)
            }
        }
        .onChange(of: preferences.chartScale) { newValue in
            SimpleAnalytics.shared.track(event: "chartscale-\(newValue)")
        }
    }
}

struct MeasurementChart_Previews: PreviewProvider {
    static var previews: some View {
        MesurementChart(chartModel: ChartModel(chartType: .temperature))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
