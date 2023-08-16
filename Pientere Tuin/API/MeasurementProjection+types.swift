//
//  MeasurementProjection+types.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 16/08/2023.
//

import Foundation

extension MeasurementProjection {
    var gardenSizeObject: GardenSize {
        get {
            if let value = self.gardenSize {
                return GardenSize(rawValue: value) ?? .undefined
            } else {
                return .undefined
            }
        }
        set {
            self.gardenSize = newValue.rawValue
        }
    }
    
    var gardenSizeString: String? {
        switch self.gardenSizeObject {
        case .undefined:
            return nil
        case .less_than_20:
            return "< 20 m²"
        case .s21_to_50:
            return "21 tot 50 m²"
        case .s51to120:
            return "51 tot 120 m²"
        case .greater_than_120:
            return "> 120 m²"
        }
    }
    
    var gardenOrientationObject: GardenOrientation {
        get {
            if let value = self.gardenOrientation {
                return GardenOrientation(rawValue: value) ?? .undefined
            } else {
                return .undefined
            }
        }
        set {
            self.gardenOrientation = newValue.rawValue
        }
    }
    
    var gardenOrientationString: String? {
        switch self.gardenOrientationObject {
        case .undefined:
            return nil
        case .south:
            return "Zuid"
        case .southwest:
            return "Zuidwest"
        case .west:
            return "West"
        case .northwest:
            return "Noordwest"
        case .north:
            return "Noord"
        case .northeast:
            return "Noordoost"
        case .east:
            return "Oost"
        case .southeast:
            return "Zuidoost"
        }
    }
    
    var soilTypeObject: SoilType {
        get {
            if let value = self.soilType {
                return SoilType(rawValue: value) ?? .undefined
            } else {
                return .undefined
            }
        }
        set {
            self.soilType = newValue.rawValue
        }
    }
    
    var soilTypeString: String? {
        switch self.soilTypeObject {
        case .undefined:
            return nil
        case .sand:
            return "Zand"
        case .lightClay:
            return "Lichte klei"
        case .zavel:
            return "Zavel"
        case .gardenSoil:
            return "Tuinaarde"
        case .pottingSoil:
            return "Potgrond"
        }
    }
    
    var goodHumidity: Range<Float>? {
        switch self.soilTypeObject {
        case .undefined:
            return nil
        case .sand:
            return 0.04..<0.10
        case .lightClay:
            return 0.23..<0.38
        case .zavel:
            return 0.16..<0.33
        case .gardenSoil:
            return 0.13..<0.31
        case .pottingSoil:
            return 0.34..<0.49
        }
    }
    
    var stressHumidity: Range<Float>? {
        switch self.soilTypeObject {
        case .undefined:
            return nil
        case .sand:
            return 0.02..<0.04
        case .lightClay:
            return 0.16..<0.23
        case .zavel:
            return 0.10..<0.16
        case .gardenSoil:
            return 0.08..<0.13
        case .pottingSoil:
            return 0.26..<0.34
        }
    }
    
    var tooWetHumidity: Range<Float>? {
        switch self.soilTypeObject {
        case .undefined:
            return nil
        case .sand:
            return 0.10..<0.4
        case .lightClay:
            return 0.38..<0.48
        case .zavel:
            return 0.33..<0.48
        case .gardenSoil:
            return 0.31..<0.49
        case .pottingSoil:
            return 0.49..<0.64
        }
    }
    
    var tooDryHumidity: Range<Float>? {
        switch self.soilTypeObject {
        case .undefined:
            return nil
        case .sand:
            return 0.0..<0.2
        case .lightClay:
            return 0.0..<0.16
        case .zavel:
            return 0.0..<0.10
        case .gardenSoil:
            return 0.0..<0.08
        case .pottingSoil:
            return 0.0..<0.26
        }
    }
    
    var humidityState: HumidityState {
        if self.goodHumidity?.contains(moisturePercentage) ?? false {
            return .healthy
        } else if self.stressHumidity?.contains(moisturePercentage) ?? false {
            return .stress
        } else if self.tooWetHumidity?.contains(moisturePercentage) ?? false {
            return .tooWet
        } else if self.tooDryHumidity?.contains(moisturePercentage) ?? false {
            return .tooDry
        }
        return .unknown
    }
}

enum HumidityState: Int {
    case unknown
    case saturated
    case tooWet
    case healthy
    case stress
    case tooDry
}

enum GardenSize: String {
    case undefined = "undefined"
    case less_than_20 = "less_than_20"
    case s21_to_50 = "21_to_50"
    case s51to120 = "51_to_120"
    case greater_than_120 = "greater_than_120"
}

enum GardenOrientation: String {
    case undefined = "undefined"
    case south = "south"
    case southwest = "southwest"
    case west = "west"
    case northwest = "northwest"
    case north = "north"
    case northeast = "northeast"
    case east = "east"
    case southeast = "southeast"
}

enum SoilType: String {
    case undefined = "undefined"
    case sand = "sand_1_1"
    case lightClay = "loam_2"
    case zavel = "sandy_loam_3"
    case gardenSoil = "sand_5"
    case pottingSoil = "sandy_loam_6"
}
