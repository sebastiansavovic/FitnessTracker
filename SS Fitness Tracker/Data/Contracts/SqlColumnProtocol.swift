//
//  SqlColumnProtocol.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/2/21.
//

import Foundation
import SQLite

protocol SqlColumnProtocol : AnyObject {
    associatedtype T : Contract
    var table:Table { get }
    func getSelectById(id: UUID) -> Table
    func getSelectByParentId(parentId: UUID) -> Table?
    func mapRowToEvent(row: Row) throws -> T
    func getSelectStatement() -> Table
    func insert(entryId: UUID, entry: T) -> Insert
}
