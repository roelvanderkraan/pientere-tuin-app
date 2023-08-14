//
//  ApiTimer.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 14/08/2023.
//

import Foundation

/// Class to handle the timing of API operations given the limits. The API of Pientere Tuinen allows 1 read call per 10 seconds.
class ApiTimer {
    var lastParseDate: Date?
    var refreshInterval: TimeInterval = 1 * 60 // in seconds
    
    /// - Returns: If parsing is allowed considering the API request limites.
    func isParseAllowed() -> Bool {
        if let lastDate = lastParseDate {
            let allowedDate = lastDate.addingTimeInterval(refreshInterval)
            if Date() > allowedDate {
                debugPrint("Parse allowed")
                lastParseDate = Date()
                return true
            }
            debugPrint("Parse not allowed")
            return false
        } else {
            lastParseDate = Date()
            return true
        }
    }
}
