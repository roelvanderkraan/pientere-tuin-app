//
//  GardenCard.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 16/08/2023.
//

import SwiftUI
import MapKit

struct GardenDetails: View {
    var latestMeasurement: MeasurementProjection
    @State private var region: MKCoordinateRegion
    
    var body: some View {
        List {
            Section("Location") {
                Map(coordinateRegion: $region)
                    .frame(idealHeight: 100)
            }
            Section {
                if let gardenSize = latestMeasurement.gardenSizeString {
                    HStack {
                        Text("Size")
                        Spacer()
                        Text("\(gardenSize)")
                            .foregroundColor(.secondary)
                    }
                }
                if let orientation = latestMeasurement.gardenOrientationString {
                    HStack {
                        Text("Orientation")
                        Spacer()
                        Text("\(orientation)")
                            .foregroundColor(.secondary)
                    }
                }
                if latestMeasurement.gardenHardeningPercentage > 0.0 {
                    HStack {
                        Text("Hardening percentage")
                        Spacer()
                        Text("\(latestMeasurement.gardenHardeningPercentage * 100, specifier: "%.0f")%")
                            .foregroundColor(.secondary)
                    }
                }
                if let soilType = latestMeasurement.soilTypeString {
                    HStack {
                        Text("Soil type")
                        Spacer()
                        Text("\(soilType)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            Section {
                Link(destination: URL(string: "https://service-portal.platform.wecity.nl/pientere-tuinen")!) {
                    Label("Edit garden information", systemImage: "safari")
                }
            }
        }
        .navigationTitle("Garden details")
    }
    
    static private func getMapRect(measurement: MeasurementProjection) -> MKCoordinateRegion {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: CLLocationDegrees(measurement.latitude), longitude: CLLocationDegrees(measurement.longitude)),
            latitudinalMeters: 750,
            longitudinalMeters: 750
        )
        return region
    }
    
    init(latestMeasurement: MeasurementProjection) {
        self.latestMeasurement = latestMeasurement
        self.region = GardenDetails.getMapRect(measurement: latestMeasurement)
    }
}

struct GardenDetails_Previews: PreviewProvider {
    static var previews: some View {
        let context =  PersistenceController.preview.container.viewContext

        GardenDetails(latestMeasurement: MeasurementStore.addTestMeasurement(to: context))
    }
}
