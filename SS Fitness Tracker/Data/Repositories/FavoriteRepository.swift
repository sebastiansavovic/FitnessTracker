//
//  FavoriteRepository.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/5/21.
//

import Foundation
import SQLite

class FavoriteRepository : Repository {
    let assetRepository: AssetRepository
    let columns:SqlFavoritesColumns
    required init(assetRepository: AssetRepository) {
        self._db = assetRepository.getSqlDb()
        self.assetRepository = assetRepository
        self.columns = SqlFavoritesColumns()
    }
    var _lastAction: dummyObservable<Favorites> = dummyObservable()
    
    
    var _db: Connection
    
    func defaultSelect(row: Row) throws -> Favorites {
        return try self.columns.mapRowToEvent(row: row)
    }
    
    func getAll() -> [Favorites] {
        let select = self.columns.getSelectStatement()
        return self.getInternal(table: select, select: defaultSelect)
    }
    
    func getById(id: UUID) -> Favorites? {
        let select = self.columns.getSelectById(id: id)
        return self.getSingleWithDefault(table: select)
    }
    
    func getByParentId(pId: UUID) -> [Favorites] {
        return Array<Favorites>()
    }
    
    func insertNew(entry: Favorites, selectInserted: Bool) -> Favorites {
        let insert = columns.insert(entryId: entry.activitySource, entry: entry)
        if self.insert(id: entry.getPrimaryId(), insert: insert) {
            //_lastAction.object = entry
        }
        if selectInserted {
            return self.getById(id: entry.activitySource)!
        }
        return entry
    }
    
    func deleteById(id: UUID) -> Bool {
        let select = columns.getSelectById(id: id)
        return self.delete(id: id, select: select)
    }
    
    func update(entry: Favorites) -> Favorites {
        let updateSql = self.columns.table.filter(self.columns.activitySource == entry.activitySource)
        do {
            try _db.run(updateSql.update(self.columns.type <- entry.type))
        }
        catch {
            return Array<Favorites>()[0]
        }
        return self.getById(id: entry.activitySource)!
    }
    
    func getByType(type: FavoriteType) -> [Favorites] {
        let select = self.columns.getSelectStatement().filter(self.columns.type == type)
        return self.getInternal(table: select, select: defaultSelect)
    }
    
    typealias T = Favorites
    
    
}
