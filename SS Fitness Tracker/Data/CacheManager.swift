//
//  CacheManager.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/2/21.
//

import Foundation


class CacheManager {
    private var doubleToDateString:[Double: String]
    
    init() {
        doubleToDateString = [Double: String]()
    }
    
    func getMonthDayString(key: Double) -> String{
        if let x = self.doubleToDateString[key] {
            return x
        }
        let date = key.toDateFrom2020().toStringMonthDay()
        self.doubleToDateString[key] = date
        return date
    }
    
}
