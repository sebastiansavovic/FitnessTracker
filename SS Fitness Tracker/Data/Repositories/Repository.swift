//
//  Repository.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/2/21.
//

import Foundation
import SQLite

typealias rowToTarget<T> = (Row) throws -> T
typealias eventHandler<T> = (EventTypes, UUID) ->  Void

protocol Repository : AnyObject {
    associatedtype T: Contract
    init(assetRepository: AssetRepository)
    var _db: Connection {
        get
    }
    var _lastAction: dummyObservable<T> {
        get
    }
    func getAll() -> [T]
    func getById(id: UUID) -> T?
    func getByParentId(pId: UUID) -> [T]
    func insertNew(entry: T, selectInserted: Bool) -> T
    func deleteById(id: UUID) -> Bool
    func update(entry: T) -> T
    func defaultSelect(row: Row) throws -> T
}

class dummyObservable<T: Contract> : ObservableObject {
    var typeOfAction: EventTypes = EventTypes.None
    var id:UUID = UUID()
    @Published var sudoChange:Bool = false
}

extension Repository {
    func registerForEvent(type: [EventTypes], callback:  @escaping eventHandler<T>) -> Any {
        return self._lastAction.objectWillChange.sink(receiveValue: {
            if let _  = type.first(where: { $0 == self._lastAction.typeOfAction }) {
                callback(self._lastAction.typeOfAction, self._lastAction.id)
            }
        })
    }
    func getSingleWithDefault(table:Table) -> T? {
        let result = self.getInternal(table: table, select: defaultSelect)
        if result.count == 1 {
            return result[0]
        }
        return nil
    }
    
    func getInternal<C>(table:Table, select: rowToTarget<C>) -> [C] {
        var result = Array<C>()
        do {
            
            for row in try self._db.prepare(table){
                let e = try select(row)
                result.append(e)
            }
        }
        catch{
            MyLog.debug("\(self) | \(error.localizedDescription)")
            return Array<C>()
        }
        return result
    }
    func delete(id: UUID, select: Table) -> Bool {
        do
        {
            if try _db.run(select.delete()) > 0 {
                self.sendNotification(id: id, type: .Deleted)
                return true
            }
            else {
                return false
            }
        }
        catch {
            return false
        }
    }
    func update(id: UUID, update: Update) -> Bool {
        do
        {
            
            if try _db.run(update) > 0 {
                self.sendNotification(id: id, type: .Updated)
                return true
            }
            else {
                return false
            }
        }
        catch {
            return false
        }
    }
    func sendNotification(id: UUID, type: EventTypes) {
        _lastAction.typeOfAction = type
        _lastAction.id = id
        _lastAction.sudoChange = !_lastAction.sudoChange
    }
    func insert(id: UUID, insert: Insert, sendNotification: Bool = true) -> Bool {
        do {
            let _ = try self._db.run(insert)
            if sendNotification {
                self.sendNotification(id: id, type: .Inserted)
            }
            return true
        }
        catch{
            let error = "could not insert:\(id.uuidString)\n \(error.localizedDescription)\n\(insert.asSQL())"
            MyLog.debug(error)
            return false
        }
    }
}
