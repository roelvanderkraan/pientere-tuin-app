//
//  MeasurementAnnotation.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 21/08/2023.
//

import SwiftUI

struct MeasurementAnnotation: View {
    var caption: String
    var value: Float
    var unit: String
    var specifier: String
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(value, specifier: specifier)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(unit)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Text(caption)
                .font(.caption)
                .foregroundColor(.secondary)

        }
        .padding(6)
        .background {
            RoundedRectangle(cornerRadius: 4)
                .foregroundStyle(Color.gray.opacity(0.12))
        }
    }
}

struct MeasurementAnnotation_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementAnnotation(caption: "2:34 PM", value: 20.0, unit: "%", specifier: "%.1f")
    }
}
