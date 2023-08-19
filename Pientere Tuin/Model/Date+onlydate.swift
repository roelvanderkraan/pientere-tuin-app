//
//  Date+onlydate.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 18/08/2023.
//

import Foundation

extension Date {
    var onlyDate: Date? {
            get {
                let calender = Calendar.current
                var dateComponents = calender.dateComponents([.year, .month, .day], from: self)
                return calender.date(from: dateComponents)
            }
        }
}
