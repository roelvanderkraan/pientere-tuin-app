//
//  WeatherAttributionView.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 18/08/2024.
//

import SwiftUI
import CachedAsyncImage

struct WeatherAttributionView: View {
    @EnvironmentObject private var weatherData: WeatherData
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if let attribution = weatherData.attribution {
            let imgURL = colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL
            Link(destination: attribution.legalPageURL, label: {
                CachedAsyncImage(url: imgURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 40, height: 8)
                .padding(.vertical)
            })
            
        }
    }
}

#Preview {
    WeatherAttributionView()
}
