//
//  MeasurementProjection+section.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 18/08/2023.
//

import Foundation

extension MeasurementProjection {
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        updateSectionTitle()
    }
    
    override public func didChangeValue(forKey key: String) {
        super.didChangeValue(forKey: key)
        
        if key == "measuredAt" {
            updateSectionTitle()
        }
    }
    
    func updateSectionTitle() {
        if let dateToFormat = measuredAt {
            measuredAtDay = measuredAt?.onlyDate
        } else {
            measuredAtDay = nil
        }
    }
    
    @objc var sectionMeasuredAt: Date {
        if let date = measuredAtDay {
            return date
        } else {
            return Date()
        }
    }
}
