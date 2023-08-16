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
        case .sand_1_1:
            return "Zand"
        case .loam_2:
            return "Lichte klei"
        case .sandy_loam_3:
            return "Zavel"
        case .sand_5:
            return "Tuinaarde"
        case .sandy_loam_6:
            return "Potgrond"
        }
    }
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
    case sand_1_1 = "sand_1_1"
    case loam_2 = "loam_2"
    case sandy_loam_3 = "sandy_loam_3"
    case sand_5 = "sand_5"
    case sandy_loam_6 = "sandy_loam_6"
}
