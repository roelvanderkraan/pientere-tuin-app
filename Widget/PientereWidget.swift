//
//  Widget.swift
//  Widget
//
//  Created by Roel van der Kraan on 10/08/2023.
//

import WidgetKit
import SwiftUI
import Intents
import CoreData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MeasurementEntry {
        MeasurementEntry(date: Date(), lastHumidity: 0.12, lastTemperature: 34)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MeasurementEntry) -> Void) {
        let entry = MeasurementEntry(date: Date(), lastHumidity: 0.23, lastTemperature: 56)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MeasurementEntry>) -> Void) {
        var entries: [MeasurementEntry] = []
        debugPrint("getTimeline")
        let fetchRequest = MeasurementProjection.fetchRequest()
        let context = PersistenceController.shared.container.viewContext
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MeasurementProjection.measuredAt, ascending: false)]
        do {
            let measurements = try context.fetch(fetchRequest)
            if let latestMeasurement = measurements.first {
                let entry = MeasurementEntry(
                    date: Date(),
                    lastHumidity: latestMeasurement.moisturePercentage,
                    lastTemperature: latestMeasurement.temperatureCelcius
                )
                entries.append(entry)
            }
        } catch {
            debugPrint("Error loading latest measurement")
        }
        let nextUpdateDate = Calendar.current.date(byAdding: .second, value: 10, to: Date())!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

struct MeasurementEntry: TimelineEntry {
    let date: Date
    var lastHumidity: Float
    var lastTemperature: Float
}

struct WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.date, style: .time)
            Spacer()
            Label("\(entry.lastHumidity * 100, specifier: "%.1f")%", systemImage: "humidity")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundColor(.blue)
            Label("\(entry.lastTemperature, specifier: "%.0f")°C", systemImage: "thermometer.medium")
                .font(.system(.body, design: .rounded, weight: .bold))
        }
        .padding()
    }
}

struct PientereWidget: Widget {
    let kind: String = "studio.skipper.Pientere-Tuin.widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Laatste meting")
        .description("Toont de laatste meting van de Pientere Tuinen sensor.")
    }
}

struct Widget_Previews: PreviewProvider {
    static var previews: some View {
        WidgetEntryView(entry: MeasurementEntry(
            date: Date(),
            lastHumidity: 0.21,
            lastTemperature: 18)
        )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
