//
//  ActivityRepository.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/3/21.
//

import Foundation
import SQLite

class ActivityRepository: Repository {
    typealias T = Activity
    var _db: Connection
    let columns:SqlActivityColumns
    let assetRepository:AssetRepository
    @Dependency(FavoriteRepository.self) var favoriteRepository: FavoriteRepository
    @Dependency(DailyWorkoutRepository.self) var dailyWorkoutRepository: DailyWorkoutRepository
    var _lastAction: dummyObservable<Activity> = dummyObservable()
    
    required init(assetRepository: AssetRepository) {
        self._db = assetRepository.getSqlDb()
        self.assetRepository = assetRepository
        self.columns = SqlActivityColumns()
        
    }
    func getAll() -> [Activity] {
        return Array<Activity>()
    }
    func getById(id: UUID) -> Activity? {
        let select = self.columns.getSelectById(id: id)
        return self.getSingleWithDefault(table: select)
    }
    func insertNew(entry: Activity, selectInserted: Bool) -> Activity {
        let newId = UUID()
        let insert = columns.insert(entryId: newId, entry: entry)
        if self.insert(id: newId,insert: insert) {
            
        }
        if selectInserted {
            return self.getById(id: newId)!
        }
        return entry
    }
    func deleteById(id: UUID) -> Bool {
        let select = columns.getSelectById(id: id)
        return self.delete(id: id, select: select)
    }
    func update(entry: Activity) -> Activity {
        let updateSql = self.columns.activities.filter(self.columns.activityId == entry.activityId)
        do {
            try _db.run(updateSql.update(self.columns.value <- entry.value,
                                         self.columns.activitySource <- entry.activitySource))
        }
        catch {
            return Array<Activity>()[0]
        }
        return self.getById(id: entry.activityId)!
    }
    func getByParentId(pId: UUID) -> [Activity] {
        return self.getActivitiesByEventId(eventId: pId)
    }
    func getActivitiesByEventId(eventId: UUID) -> [Activity] {
        if let select = self.columns.getSelectByParentId(parentId: eventId){
            return self.getInternal(table: select, select: defaultSelect)
        }
        return Array<Activity>()
    }
    func defaultSelect(row: Row) throws -> Activity {
        return try self.columns.mapRowToEvent(row: row, name: {
            (id) in
            return self.assetRepository.getRingActivityById(id: id).name
        })
    }
    func getActivitiesByActivityId(id: UUID, name: String) -> [ActivityWithDateDto] {
        let eventColumns = SqlEventColumns()
        
        let select = columns.activities.join(eventColumns.table, on: columns.activities[columns.eventId] == eventColumns.table[eventColumns.eventId]).select(columns.activitySource, columns.activityId, eventColumns.eventDate, columns.value).filter(columns.activitySource == id).order(eventColumns.table[eventColumns.eventDate].desc)
        
        return self.getInternal(table: select, select: {
            (row) -> ActivityWithDateDto in
            
            let activityId = try row.get(columns.activityId)
            let activitySource = try row.get(columns.activitySource)
            let eventDate:Date = try row.get(eventColumns.eventDate)
            let value:Int = try row.get(columns.value)
            
            return ActivityWithDateDto(activityId: activityId, activitySource: activitySource, eventDate: eventDate, activityName: name, value: value)
        })
    }
    func getAggregateDailyWorkout() -> [ActivityAggregateDto] {
        let dailyTable = self.dailyWorkoutRepository.columns
        let selectDaily = self.dailyWorkoutRepository.getSelectForActivitiesForDay(dayOfWeek: Date().getDayOfWeek())
        let select = columns.activities.group(self.columns.table[columns.activitySource], dailyTable.table[dailyTable.order])
            .join(selectDaily, on:  self.columns.table[self.columns.activitySource] == dailyTable.table[dailyTable.activitySource])
            .select(dailyTable.table[columns.activitySource], columns.value.sum, dailyTable.order)
            .order(dailyTable.order.asc)
        return self.getInternal(table: select, select: sumAggregateMapper)
    }
    func getAggreateActivities() -> [ActivityAggregateDto] {
        let select = columns.activities.group(columns.activitySource)
            .select(columns.activitySource, columns.value.sum)
            .order(columns.value.sum.desc)
        
        return self.getInternal(table: select, select: sumAggregateMapper)
    }
    private func getCanFavoriteCateggoriesIds() -> [UUID] {
        
        let ringActivity = SqlRingActivityColumns()
        let innerSql = ringActivity.table.filter(ringActivity.canFavorite == true).select(ringActivity.categoryId)
        return self.getInternal(table: innerSql, select:  {
            return try $0.get(ringActivity.categoryId)
        })
    }
    private func getActivityIdsIgnored() -> [UUID] {
        return favoriteRepository.getByType(type: .Ignore).map{
            $0.activitySource
        }
    }
    private func getBaselineAggregate() -> Table {
        let ids = self.getCanFavoriteCateggoriesIds()
        let ignored = self.getActivityIdsIgnored()
        return columns.activities.filter(ids.contains(self.columns.categoryId) && !ignored.contains(self.columns.activitySource)).group(columns.activitySource)
            .select(columns.activitySource, columns.value.sum)
    }
    
    func getTop5Activities() -> [ActivityAggregateDto] {
        let select = self.getBaselineAggregate()
            .order(columns.value.sum.desc).limit(5)
        
        return self.getInternal(table: select, select: sumAggregateMapper)
    }
    func getLeastUsedActivities() -> [ActivityAggregateDto] {
        let select = self.getBaselineAggregate()
            .order(columns.value.sum.asc).limit(5)
        
        return self.getInternal(table: select, select: sumAggregateMapper)
    }
    private func sumAggregateMapper(row: Row) throws -> ActivityAggregateDto
    {
        let sum = try row.get(columns.value.sum)!
        let activityUUID = try row.get(columns.activitySource)
        let activity = self.assetRepository.getRingActivityById(id: activityUUID)
        return ActivityAggregateDto(activitySource: activityUUID, sum: sum, activityName: activity.name)
    }
    
}
