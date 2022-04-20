//
//  RingActivity.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/9/21.
//

import Foundation
import SQLite


class RingActivity: Contract {
    let activitySource: UUID
    let categoryId: UUID
    let canFavorite: Bool
    init(activitySource: UUID, categoryId: UUID, canFavorite: Bool) {
        self.activitySource = activitySource
        self.canFavorite = canFavorite
        self.categoryId = categoryId
    }
    
    func getPrimaryId() -> UUID {
        return self.activitySource
    }
    
    func cloneShallowWithNewParentId(id: UUID) -> RingActivity {
        return RingActivity(activitySource: id, categoryId: self.categoryId, canFavorite: self.canFavorite)
    }
    typealias T = RingActivity
}

class SqlRingActivityColumns: SqlColumnProtocol {
    var table = Table("RingActivity")
    let activitySource = Expression<UUID>("ActivitySource")
    let categoryId = Expression<UUID>("CategoryId")
    let canFavorite = Expression<Bool>("canFavorite")
    
    func getSelectById(id: UUID) -> Table {
        return self.getSelectStatement().filter(self.activitySource == id)
    }
    
    func getSelectByParentId(parentId: UUID) -> Table? {
        return nil
    }
    
    func mapRowToEvent(row: Row) throws -> RingActivity {
        let id = try row.get(self.activitySource)
        let cid = try row.get(self.categoryId)
        let cf = try row.get(self.canFavorite)
        return RingActivity(activitySource: id, categoryId: cid, canFavorite: cf)
    }
    
    func getSelectStatement() -> Table {
        return self.table.select(self.activitySource, self.categoryId, self.canFavorite)
    }
    
    func insert(entryId: UUID, entry: RingActivity) -> Insert {
        return self.table.insert(self.activitySource <- entry.activitySource,
                                 self.categoryId <- entry.categoryId,
                                 self.canFavorite <- entry.canFavorite)
    }
    
    typealias T = RingActivity
    
    
}
