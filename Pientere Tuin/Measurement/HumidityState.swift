//
//  HumidityState.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 16/08/2023.
//

import SwiftUI

struct HumidityStateText: View {
    var humidityState: HumidityState
    var body: some View {
        switch humidityState {
        case .healthy:
            Text("\(Image(systemName: "checkmark.circle.fill")) Goede vochtigheid")
                .foregroundColor(.secondary)
        case .saturated:
            Text("\(Image(systemName: "water.waves")) Verzadigd")
                .foregroundColor(.blue)
        case .tooWet:
            Text("\(Image(systemName: "drop.fill")) Te nat")
                .foregroundColor(.blue)
        case .stress:
            Text("\(Image(systemName: "water.waves.and.arrow.down")) Te droog")
                .foregroundColor(.orange)
                .bold()
        case .tooDry:
            Text("\(Image(systemName: "drop.triangle.fill")) Te droog")
                .foregroundColor(.orange)
                .bold()
        default:
            EmptyView()
        }
    }
}

struct HumidityStateText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HumidityStateText(humidityState: .healthy)
            HumidityStateText(humidityState: .saturated)
            HumidityStateText(humidityState: .stress)
            HumidityStateText(humidityState: .tooDry)
            HumidityStateText(humidityState: .tooWet)
            HumidityStateText(humidityState: .unknown)
        }
    }
}
