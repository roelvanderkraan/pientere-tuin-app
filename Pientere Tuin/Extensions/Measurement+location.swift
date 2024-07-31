//
//  Measurement+location.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 31/07/2024.
//

import Foundation
import CoreLocation

extension MeasurementProjection {
    func location() -> CLLocation {
        return CLLocation(latitude: CLLocationDegrees(self.latitude), longitude: CLLocationDegrees(self.longitude))
    }
}
