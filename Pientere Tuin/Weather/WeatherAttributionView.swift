//
//  WeatherAttributionView.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 18/08/2024.
//

import SwiftUI

struct WeatherAttributionView: View {
    @EnvironmentObject private var weatherData: WeatherData
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if let attribution = weatherData.attribution {
            let imgURL = colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL
            Link(destination: attribution.legalPageURL, label: {
                AsyncImage(url: imgURL, scale: 0.5) { phase in
                    switch phase {
                    case .failure:
                        Text("\(Image(systemName: "apple.logo")) Weer")
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    default:
                        Text("\(Image(systemName: "apple.logo")) Weer")
                    }
                }
            })
            .foregroundStyle(.primary)
            .bold()
            .frame(height: 10)
            .font(.caption)
            
        }
    }
}

#Preview {
    WeatherAttributionView()
        .environmentObject(WeatherData.shared)
}
