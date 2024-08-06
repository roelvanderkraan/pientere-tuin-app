//
//  Formatters.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 16/08/2023.
//

import Foundation

struct Formatters {
    static let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter
    }()
    
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d")
        return formatter
    }()
}

//
//  RelativeDateFormatter.swift
//  Arya prototype
//
//  Created by Studio Skipper on 20/03/2019.
//  Copyright © 2019 Studio Skipper. All rights reserved.
//


class RelativeDateFormatter {
    static var componentFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .month, .weekOfMonth]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .full
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }
    
    static var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        return formatter
    }
    
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE d MMMM")
        return formatter
    }
    
    static var calendar = Calendar.current
    
    static func relativeDateText(from: Date, to: Date) -> String? {
        // If date is in the past ,return nil
        if (calendar.compare(from, to: to, toGranularity: .day) == .orderedDescending) {
            return nil
        }
        // If date is today, return nil
        if calendar.isDate(from, inSameDayAs: to) {
            return "Vandaag"
        }
        // If to date is in current week, return day name
        
        if calendar.isDateInTomorrow(to) {
            return "Morgen"
        }
        
        let dateComponents = calendar.dateComponents([.weekOfMonth], from: from, to: to)
        // If within same week, return the name of the day
        if dateComponents.weekOfMonth == 0 {
            return dayFormatter.string(from: to)
        }
        
        return dateFormatter.string(from: to)
    }
    
    
}

struct MeasurementFormatter {
    static func formatMeasurementToMM(measurement: Measurement<UnitLength>) -> String {
        let millimeters = measurement.converted(to: .millimeters)
        let roundedStyle = FloatingPointFormatStyle<Double>(locale: .autoupdatingCurrent)
            .rounded(rule: .toNearestOrAwayFromZero, increment: 1)
        return millimeters.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: roundedStyle))
    }
}

