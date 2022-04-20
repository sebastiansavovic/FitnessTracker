//
//  DailyWorkoutRepository.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/11/21.
//

import Foundation
import SQLite

class DailyWorkoutRepository : Repository {
    required init(assetRepository: AssetRepository) {
        _db = assetRepository.getSqlDb()
        self.assetRepository = assetRepository
        columns = SqlDailyWorkOutColumns()
    }
    
    var _db: Connection
    let assetRepository: AssetRepository
    let columns:SqlDailyWorkOutColumns
    var _lastAction: dummyObservable<DailyWorkOut> = dummyObservable()
    
    func getAll() -> [DailyWorkOut] {
        let select = self.columns.getSelectStatement()
        return self.getInternal(table: select, select: defaultSelect)
    }
    
    func getById(id: UUID) -> DailyWorkOut? {
        let select = self.columns.getSelectById(id: id)
        return self.getSingleWithDefault(table: select)
    }
    
    func getByParentId(pId: UUID) -> [DailyWorkOut] {
        return [DailyWorkOut]()
    }
    
    func insertNew(entry: DailyWorkOut, selectInserted: Bool) -> DailyWorkOut {
        let newId = UUID()
        let insert = columns.insert(entryId: newId, entry: entry)
        if self.insert(id: newId, insert: insert){
        }
        if selectInserted {
            return self.getById(id: newId)!
        }
        return entry
    }
    func getSelectForActivitiesForDay(dayOfWeek: DayOfWeek) -> Table {
        return self.columns.getSelectStatement().filter(self.columns.dayOfWeek == dayOfWeek)
    }
    func getActivitiesForDay(dayOfWeek: DayOfWeek) -> [DailyWorkOut] {
        let select = getSelectForActivitiesForDay(dayOfWeek: dayOfWeek).order(self.columns.order.asc)
        return self.getInternal(table: select, select: defaultSelect)
    }
    
    func deleteById(id: UUID) -> Bool {
        let select = columns.getSelectById(id: id)
        return self.delete(id: id, select: select)
    }
    
    func update(entry: DailyWorkOut) -> DailyWorkOut {
        let updateSql = self.columns.table.filter(self.columns.dailyWorkOutId == entry.dailyWorkOutId)
        let _ = self.update(id: entry.dailyWorkOutId, update: updateSql.update(self.columns.order <- entry.order))
        return self.getById(id: entry.dailyWorkOutId)!
    }
    
    func defaultSelect(row: Row) throws -> DailyWorkOut {
        let e = try self.columns.mapRowToEvent(row: row, name: {
            (id) in
            return self.assetRepository.getRingActivityById(id: id).name
        })
        return e
    }
    
    typealias T = DailyWorkOut
    
    
}
