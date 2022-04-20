//
//  DailyWorkOut.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/2/21.
//

import Foundation
import SQLite
import UIKit

class DailyWorkOut: Contract {
    typealias T = DailyWorkOut
    
    let dailyWorkOutId:UUID
    let dayOfWeek: DayOfWeek
    let activitySource: UUID
    let order: Int
    let name: String
    init(dailyWorkOutId: UUID, dayOfWeek: DayOfWeek, activitySource: UUID, order: Int, name: String) {
        self.dailyWorkOutId = dailyWorkOutId
        self.dayOfWeek = dayOfWeek
        self.order = order
        self.activitySource = activitySource
        self.name = name
    }
    func getPrimaryId() -> UUID {
        return self.activitySource
    }
    func cloneShallowWithNewParentId(id: UUID) -> DailyWorkOut {
        return DailyWorkOut(dailyWorkOutId: id, dayOfWeek: self.dayOfWeek, activitySource: self.activitySource, order: self.order, name: self.name)
    }
    func cloneShallowWithNewOrder(order: Int) -> DailyWorkOut {
        return DailyWorkOut(dailyWorkOutId: self.dailyWorkOutId, dayOfWeek: self.dayOfWeek, activitySource: self.activitySource, order: order, name: self.name)
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

class SqlDailyWorkOutColumns : SqlColumnProtocol {
    typealias T = DailyWorkOut
 
    var dailyWorkOutId = Expression<UUID>("DailyWorkOutId")
    let dayOfWeek = Expression<DayOfWeek>("DayOfWeek")
    let activitySource = Expression<UUID>("ActivitySource")
    let order = Expression<Int>("Order")
    var table:Table = Table("DailyWorkOut")
    func insert(entryId: UUID, entry: DailyWorkOut) -> Insert {
        return self.table.insert(self.dailyWorkOutId <- entryId,
                                        self.dayOfWeek <- entry.dayOfWeek,
                                        self.activitySource <- entry.activitySource,
                                        self.order <- entry.order)
    }
    func getSelectById(id: UUID) -> Table {
        return self.getSelectStatement().filter(self.dailyWorkOutId == id)
    }
    func mapRowToEvent(row: Row) throws -> DailyWorkOut {
        return try self.mapRowToEvent(row: row, name: {
            (id) in
            ""
        })
    }
    func mapRowToEvent(row: Row, name: GetNamebyId) throws -> DailyWorkOut {
        let pid = try row.get(self.dailyWorkOutId)
        let id = try row.get(self.activitySource)
        let order = try row.get(self.order)
        let dayOfWeek = try row.get(self.dayOfWeek)
        let localName = name(id)
        return DailyWorkOut(dailyWorkOutId: pid,dayOfWeek: dayOfWeek, activitySource: id, order: order, name: localName)
    }
    func getSelectStatement() -> Table {
        return table.select(table[self.dailyWorkOutId], table[self.dayOfWeek], table[self.activitySource], table[self.order])
    }
    func getSelectByParentId(parentId: UUID) -> Table? {
        return nil
    }
}

