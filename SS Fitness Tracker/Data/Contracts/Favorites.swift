//
//  Favorites.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/2/21.
//

import Foundation
import SQLite

class Favorites: Contract {
    typealias T = Favorites
    let activitySource: UUID
    let type: FavoriteType
    init(activitySource: UUID, type: FavoriteType) {
        self.activitySource = activitySource
        self.type = type
    }
    func getPrimaryId() -> UUID {
        return self.activitySource
    }
    func cloneShallowWithNewParentId(id: UUID) -> Favorites {
        return Favorites(activitySource: self.activitySource, type: self.type)
    }
}

class SqlFavoritesColumns : SqlColumnProtocol {
    typealias T = Favorites
    var table:Table = Table("Favorites")
    let activitySource = Expression<UUID>("ActivitySource")
    let type = Expression<FavoriteType>("Type")
    func getSelectById(id: UUID) -> Table {
        return self.getSelectStatement().filter(self.activitySource == id)
    }
    func insert(entryId: UUID, entry: Favorites) -> Insert {
        return self.table.insert(self.activitySource <- entryId,
                                     self.type <- entry.type)
    }
    func mapRowToEvent(row: Row) throws -> Favorites {
        let id = try row.get(self.activitySource)
        let type = try row.get(self.type)
        return Favorites(activitySource: id, type: type)
    }
    func getSelectStatement() -> Table {
        return table.select(self.activitySource, self.type)
    }
    func getSelectByParentId(parentId: UUID) -> Table? {
        return nil
    }
}
