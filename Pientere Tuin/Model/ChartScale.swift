//
//  ChartScale.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 14/08/2023.
//

import Foundation

enum ChartScale: String, CaseIterable, Identifiable, Equatable {
    case week
    case month
    case day
    case all
    var id: Self { self }
}

enum ChartType {
    case moisture
    case temperature
}
