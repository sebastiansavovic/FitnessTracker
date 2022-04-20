//
//  ActivityDto.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 2/28/21.
//

import Foundation
import UIKit

public class ActivityAggregateDto: Contract {
    public typealias T = ActivityAggregateDto
    let activitySource:UUID
    let sum:Int
    let activityName:String
    init(activitySource:UUID, sum:Int, activityName:String){
        self.activitySource = activitySource
        self.activityName = activityName
        self.sum = sum
    }
    public func getPrimaryId() -> UUID {
        return self.activitySource
    }
    public func cloneShallowWithNewParentId(id: UUID) -> ActivityAggregateDto {
        return ActivityAggregateDto(activitySource: self.activitySource, sum: self.sum, activityName: self.activityName)
    }
    public func getIcon() -> UIImage? {
        let namedImage = "\(self.activitySource.uuidString.lowercased()).png"
        if let icon = UIImage(named: namedImage) {
            return icon
        }
        if let icon = UIImage(named: "main.jpg"){
            return icon
        }
        return nil
    }
}

public class ActivityWithDateDto: Contract {
    public typealias T = ActivityWithDateDto
    
    let activityId:UUID
    let activitySource:UUID
    let eventDate:Date
    let activityName:String
    let value:Int
    public init(activityId:UUID, activitySource:UUID, eventDate:Date, activityName:String, value:Int){
        self.activityId = activityId
        self.activitySource = activitySource
        self.eventDate = eventDate
        self.activityName = activityName
        self.value = value
    }
    public func toLineString() -> String {
        let dateString = self.eventDate.toShortDateString()
        return "\(dateString) (\(self.value))"
    }
    
    public func getPrimaryId() -> UUID {
        return activitySource
    }
    public func cloneShallowWithNewValue(value: Int) -> ActivityWithDateDto {
        return ActivityWithDateDto(activityId: self.activityId, activitySource: self.activitySource, eventDate: self.eventDate, activityName: self.activityName, value: value)
    }
    public func cloneShallowWithNewParentId(id: UUID) -> ActivityWithDateDto {
        return ActivityWithDateDto(activityId: id, activitySource: self.activitySource, eventDate: self.eventDate, activityName: self.activityName, value: self.value)
    }
    
}
