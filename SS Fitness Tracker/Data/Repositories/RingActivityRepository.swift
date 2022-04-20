//
//  RingActivityRepository.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/9/21.
//

import Foundation
import SQLite

class RingActivityRepository: Repository {
    required init(assetRepository: AssetRepository) {
        _db = assetRepository.getSqlDb()
        columns = SqlRingActivityColumns()
    }
    
    var _db: Connection
    let columns:SqlRingActivityColumns
    
    var _lastAction: dummyObservable<RingActivity> = dummyObservable()
    
    func defaultSelect(row: Row) throws -> RingActivity {
        return try self.columns.mapRowToEvent(row: row)
    }
    
    func getAll() -> [RingActivity] {
        let select = self.columns.getSelectStatement()
        return self.getInternal(table: select, select: defaultSelect)
    }
    
    func getById(id: UUID) -> RingActivity? {
        let select = self.columns.getSelectById(id: id)
        return self.getSingleWithDefault(table: select)
    }
    
    func getByParentId(pId: UUID) -> [RingActivity] {
        return [RingActivity]()
    }
    
    func insertNew(entry: RingActivity, selectInserted: Bool) -> RingActivity {
        let newId = entry.activitySource
        let insert = self.columns.insert(entryId: newId, entry: entry)
        if self.insert(id: newId, insert: insert){
        }
        if selectInserted {
            return self.getById(id: newId)!
        }
        return entry
    }
    
    func deleteById(id: UUID) -> Bool {
        false
    }
    
    func update(entry: RingActivity) -> RingActivity {
        return entry
    }
    
    typealias T = RingActivity
    
    
}
