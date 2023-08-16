//
//  GardenDetails.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 16/08/2023.
//

import SwiftUI

struct GardenDetails: View {
    @State private var region: MKCoordinateRegion

    var body: some View {
        List {
            Text("Locatie")
            Map(coordinateRegion: $region)
                .frame(idealHeight: 100)
            Text("Oppervlakte")
            Text("Orientatie")
            Text("Verharding")
            Text("Grondsoort")
            Text("Wijzigen")
        }
    }
}

struct GardenDetails_Previews: PreviewProvider {
    static var previews: some View {
        GardenDetails()
    }
}
