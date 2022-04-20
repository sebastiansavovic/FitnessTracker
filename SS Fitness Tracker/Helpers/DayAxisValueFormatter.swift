//
//  DayAxisValueFormatter.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/2/21.
//

import Foundation
import Charts


class DayAxisValueFormatter : NSObject, IAxisValueFormatter {
    @Dependency(CacheManager.self)var cache:CacheManager
    weak var chart: BarLineChartViewBase?
    
    init(chart: BarLineChartViewBase) {
        self.chart = chart
    }
    
    func stringForValue(_ value: Double,
                        axis: AxisBase?) -> String {
        return self.cache.getMonthDayString(key: value)
    }
    
}


