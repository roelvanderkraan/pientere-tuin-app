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
        MeasurementEntry(date: Date(), lastHumidity: 0.12, lastTemperature: 34, humidityState: .healthy)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MeasurementEntry) -> Void) {
        let entry = MeasurementEntry(date: Date(), lastHumidity: 0.23, lastTemperature: 56, humidityState: .healthy)
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
                    date: latestMeasurement.measuredAt ?? Date(),
                    lastHumidity: latestMeasurement.moisturePercentage,
                    lastTemperature: latestMeasurement.temperatureCelcius?.floatValue,
                    humidityState: latestMeasurement.humidityState
                )
                entries.append(entry)
            }
        } catch {
            debugPrint("Error loading latest measurement")
        }
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

struct MeasurementEntry: TimelineEntry {
    let date: Date
    var lastHumidity: Float
    var lastTemperature: Float?
    var humidityState: HumidityState
}

struct WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if #available(iOS 17.0, *) {
            ios17Widget
        } else {
            ios16Widget
        }
    }
    
    var ios16Widget: some View {
        HStack {
            baseWidget
            .padding()
            Spacer()
        }
    }
    
    @available(iOSApplicationExtension 17.0, *)
    var ios17Widget: some View {
        HStack {
            baseWidget
            Spacer()
        }
        .containerBackground(for: .widget) {
            Color.white
        }
    }
    
    var baseWidget: some View {
        VStack(alignment: .leading) {
            Text(entry.date, style: .time)
                .minimumScaleFactor(0.25)
                .foregroundColor(.secondary)
            Spacer()
            if let temperature = entry.lastTemperature {
                Text("\(temperature, specifier: "%.0f")°C")
                    .minimumScaleFactor(0.25)
                    .font(.system(.body, design: .rounded, weight: .bold))
            }
            Label("\(entry.lastHumidity * 100, specifier: "%.1f")%", systemImage: "drop.fill")
                .minimumScaleFactor(0.25)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundColor(.blue)
                .bold()
                .lineLimit(1)
        }
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
            lastTemperature: 18,
            humidityState: .healthy
        )
        )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
