//
//  Preferences.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 17/08/2023.
//

import SwiftUI

class Preferences: ObservableObject {
    static var shared = Preferences()
    
    @Published var chartScale: ChartScale = .week
}
