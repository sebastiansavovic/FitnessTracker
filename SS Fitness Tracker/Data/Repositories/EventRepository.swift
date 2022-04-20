//
//  EventRepository.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/2/21.
//

import Foundation
import SQLite

class EventRepository : Repository {
    typealias S = SqlColumnProtocol
    typealias T = Event
    func applyChildren(parent: Event, children: [Activity]) {
        parent.activities = children
    }
    @Dependency(ActivityRepository.self)var activityRepository: ActivityRepository

    let _db: Connection
 
    let columns:SqlEventColumns
    var _lastAction: dummyObservable<Event> = dummyObservable()
    
    required init(assetRepository: AssetRepository) {
        self._db = assetRepository.getSqlDb()
        self.columns = SqlEventColumns()
    }
    func defaultSelect(row: Row) throws -> Event {
        let e = try self.columns.mapRowToEvent(row: row)
        e.activities = self.activityRepository.getByParentId(pId: e.eventId)
        return e
    }
    func getEventsFromLastWeek() -> [Event] {
        let now = Date()
        let date = Calendar.current.date(byAdding: .day, value: -10, to: now)!
        let select = self.columns.getSelectStatement().filter(columns.eventDate > date).order(columns.eventDate.asc)
        return self.getInternal(table: select, select: defaultSelect)
    }
    func getPreviousMonthsEvents(_ numberOfMonths:Int) -> [Event] {
        let now = Date()
        let target = numberOfMonths > 0 ? numberOfMonths * -1 : numberOfMonths
        let date = Calendar.current.date(byAdding: .month, value: target, to: now)!
        let select = self.columns.getSelectStatement().filter(columns.eventDate > date).order(columns.eventDate.desc)
        return self.getInternal(table: select, select: defaultSelect)
    }
    func getAll() -> [Event] {
        let select = self.columns.getSelectStatement()
        return self.getInternal(table: select, select: defaultSelect)
    }
    func getByParentId(pId: UUID) -> [Event] {
      return Array<Event>()
    }
    func getById(id: UUID) -> Event? {
        let select = self.columns.getSelectById(id: id)
        return self.getSingleWithDefault(table: select)
    }
    func insertNew(entry: Event, selectInserted: Bool) -> Event {
        let newId = UUID()
        let insert = columns.insert(entryId: newId, entry: entry)
        if self.insert(id: newId, insert: insert, sendNotification: false){
            if let activities = entry.activities {
                for activity in activities {
                    let clonedActivity = activity.cloneShallowWithNewParentId(id: newId)
                    let _ = self.activityRepository.insertNew(entry: clonedActivity, selectInserted: false)
                }
            }
            self.sendNotification(id: newId, type: .Inserted)
        }
        if selectInserted {
            return self.getById(id: newId)!
        }
        return entry
    }
    func deleteById(id: UUID) -> Bool {
        if let event = self.getById(id: id){
            for activity in event.activities ?? [] {
                let _ = self.activityRepository.deleteById(id: activity.activityId)
            }
            let select = columns.getSelectById(id: id)
            return self.delete(id: id, select: select)
        }
        return false
    }
    func update(entry: Event) -> Event {
        return Array<Event>()[0]
    }
}
