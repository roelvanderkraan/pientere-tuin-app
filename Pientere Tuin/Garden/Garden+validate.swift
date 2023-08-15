//
//  Garden+validate.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 15/08/2023.
//

import Foundation

extension Garden {
    func validateApiKey() -> Bool {
        if apiKey == nil {
            return false
        }
        return true
    }
}
