//
//  GardenCard.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 16/08/2023.
//

import SwiftUI
import MapKit
import SwiftSimpleAnalytics

struct GardenDetails: View {
    var latestMeasurement: MeasurementProjection
    @State private var region: MKCoordinateRegion
    
    var body: some View {
        List {
            Section("Locatie") {
                if #available(iOS 17.0, *) {
                    Map(bounds: MapCameraBounds(centerCoordinateBounds: region, minimumDistance: 100)) {
                        Marker("Tuin", coordinate: region.center)
                            .tint(.green)
                    }
                    .frame(idealHeight: 200)
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 8, height: 8)))
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                } else {
                    Map(coordinateRegion: $region)
                        .frame(idealHeight: 200)
                }
            }
            Section {
                if let gardenSize = latestMeasurement.gardenSizeString {
                    HStack {
                        Text("Oppervlakte")
                        Spacer()
                        Text("\(gardenSize)")
                            .foregroundColor(.secondary)
                    }
                }
                if let orientation = latestMeasurement.gardenOrientationString {
                    HStack {
                        Text("Oriëntatie")
                        Spacer()
                        Text("\(orientation)")
                            .foregroundColor(.secondary)
                    }
                }
                if latestMeasurement.gardenHardeningPercentage > 0.0 {
                    HStack {
                        Text("Percentage verharding")
                        Spacer()
                        Text("\(latestMeasurement.gardenHardeningPercentage * 100, specifier: "%.0f")%")
                            .foregroundColor(.secondary)
                    }
                }
                if let soilType = latestMeasurement.soilTypeString {
                    HStack {
                        Text("Grondsoort")
                        Spacer()
                        Text("\(soilType)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            Section {
                Link(destination: URL(string: "https://service-portal.platform.wecity.nl/pientere-tuinen")!) {
                    Label("Bewerk via Mijn Pientere Tuin", systemImage: "pencil")
                }
            }
        }
        .navigationTitle("Tuindetails")
        .onAppear {
            SimpleAnalytics.shared.track(path: ["gardenDetails"])
        }
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
