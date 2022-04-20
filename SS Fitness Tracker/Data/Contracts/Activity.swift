//
//  Activity.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 2/27/21.
//

import Foundation
import SQLite

typealias GetNamebyId = (UUID) -> String

public class Activity: Contract, Codable {
    public typealias T = Activity
    public let activityId, eventId, categoryId, activitySource: UUID
    public let value, cumulativeValue: Int
    public let modifier, originalValue: String
    public let name: String?
    
    enum CodingKeys: String, CodingKey {
        case activityId = "ActivityId"
        case eventId = "EventId"
        case categoryId = "CategoryId"
        case activitySource = "ActivitySource"
        case value = "Value"
        case cumulativeValue = "CumulativeValue"
        case modifier = "Modifier"
        case originalValue = "OriginalValue"
        case name = "Name"
    }
    
    public init(activityId: UUID, eventId: UUID, categoryId: UUID, activitySource: UUID, value: Int, cumulativeValue: Int, modifier: String, originalValue: String, name: String?) {
        self.activityId = activityId
        self.eventId = eventId
        self.categoryId = categoryId
        self.activitySource = activitySource
        self.value = value
        self.cumulativeValue = cumulativeValue
        self.modifier = modifier
        self.originalValue = originalValue
        self.name = name
    }
    public func getPrimaryId() -> UUID {
        return self.activityId
    }
    public func cloneShallowWithNewParentId(id: UUID) -> Activity {
        return Activity(activityId: self.activityId, eventId: id,  categoryId: self.categoryId, activitySource: self.activitySource, value: self.value, cumulativeValue: self.cumulativeValue, modifier: self.modifier, originalValue: self.originalValue, name: self.name)
    }
    
    public func cloneWithNewValue(newValue: Int) -> Activity {
        return Activity(activityId: self.activityId, eventId: self.eventId, categoryId: self.categoryId, activitySource: self.activitySource, value: newValue, cumulativeValue: self.cumulativeValue, modifier: self.modifier, originalValue: self.originalValue, name: self.name)
    }
    public func cloneWithNewValue(newSource: UUID) -> Activity {
        return Activity(activityId: self.activityId, eventId: self.eventId, categoryId: self.categoryId, activitySource: newSource, value: self.value, cumulativeValue: self.cumulativeValue, modifier: self.modifier, originalValue: self.originalValue, name: self.name)
    }
}

class SqlActivityColumns : SqlColumnProtocol {
    typealias T = Activity
    var table:Table {
        get {
            return self.activities
        }
    }
    let activities = Table("Activity")
    let activityId = Expression<UUID>("ActivityId")
    let eventId = Expression<UUID>("EventId")
    let categoryId = Expression<UUID>("CategoryId")
    let activitySource = Expression<UUID>("ActivitySource")
    let value = Expression<Int>("Value")
    let cumulativeValue = Expression<Int>("CumulativeValue")
    let modifier = Expression<String>("Modifier")
    let originalValue = Expression<String>("OriginalValue")
    
    func insert(entryId: UUID, entry: Activity) -> Insert {
        return activities.insert(self.eventId <- entry.eventId,
                                 self.activityId <- entryId,
                                 self.activitySource <- entry.activitySource,
                                 self.categoryId <- entry.categoryId,
                                 self.value <- entry.value,
                                 self.cumulativeValue <- entry.cumulativeValue,
                                 self.modifier <- entry.modifier,
                                 self.originalValue <- entry.originalValue)
    }
    func mapRowToEvent(row: Row) throws -> Activity {
        return try self.mapRowToEvent(row: row, name: {
            (id) in
            ""
        })
    }
    func mapRowToEvent(row: Row, name: GetNamebyId) throws -> Activity {
        let eId = try row.get(self.eventId)
        let sId = try row.get(self.activitySource)
        let id = try row.get(self.activityId)
        let cId = try row.get(self.categoryId)
        
        let val = try row.get(self.value)
        let cVal = try row.get(self.cumulativeValue)
        let mVal = try row.get(self.modifier)
        let oVal = try row.get(self.originalValue)
        let localName = name(sId)
        
        return Activity(activityId: id, eventId: eId, categoryId: cId, activitySource: sId, value: val, cumulativeValue: cVal, modifier: mVal, originalValue: oVal, name: localName)
    }
    func getSelectById(id: UUID) -> Table {
        return self.getSelectStatement().filter(self.activityId == id)
    }
    func getSelectByEventId(eId: UUID) -> Table {
        return self.getSelectStatement().filter(self.eventId == eId)
    }
    func getSelectStatement() -> Table{
        return activities.select(self.activityId, self.eventId, self.activitySource, self.value, self.cumulativeValue, self.modifier, self.originalValue, self.categoryId)
    }
    func getSelectByParentId(parentId: UUID) -> Table? {
        return self.getSelectStatement().filter(self.eventId == parentId)
    }
}
