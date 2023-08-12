//
//  NSPredicate+date.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 12/08/2023.
//

import Foundation

extension NSPredicate {
    // https://stackoverflow.com/questions/8364495/nspredicate-for-finding-events-that-occur-between-a-certain-date-range

    static func filter(key: String, date: Date, calendar: Calendar = Calendar(identifier: .gregorian), scale: ChartScale) -> NSPredicate? {

        let offsetComponents = NSDateComponents()
        switch scale {
        case .month:
            offsetComponents.month = -1
        case .week:
            offsetComponents.weekOfYear = -1
        case .all:
            return nil
        case .day:
            offsetComponents.day = -1
        }
        let startDate = calendar.date(byAdding: offsetComponents as DateComponents, to: date)!
        debugPrint("\(startDate) - \(date)")
        return NSPredicate(format: "\(key) >= %@",
                           startDate as NSDate)
    }
}
