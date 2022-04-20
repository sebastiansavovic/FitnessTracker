//
//  DataRepository.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 2/23/21.
//

import Foundation
import SQLite
typealias randomFunction = () -> RingFitActivity

class DataRepository {
    private let assetRepository:AssetRepository
    private  let db: Connection
    @Dependency(EventRepository.self)var eventRepository:EventRepository
    @Dependency(RingActivityRepository.self) var ringActivityRepository:RingActivityRepository
    @Dependency(DailyWorkoutRepository.self) var dailyWorkoutRepository:DailyWorkoutRepository
    
    init(assetRepository:AssetRepository) {
        self.assetRepository = assetRepository
        do {
            let path = self.assetRepository.getPathForActivitiesDatabase()
            self.db = try Connection(path)
        }
        catch {
            fatalError("Activities Database not available")
        }
    }
    func insertSeedData() {
        let canFavorites = self.assetRepository.getRingFitCategories().reduce(into: [UUID: Bool](), {
            $0[$1.categoryId] = $1.canFavorite
        })
        let allactivities = self.assetRepository.getRingFitActivities()
        for a in allactivities {
            let canFavorite = canFavorites[a.categoryId]!
            let ringActivity = RingActivity(activitySource: a.activitySource, categoryId: a.categoryId, canFavorite: canFavorite)
            let _ = ringActivityRepository.insertNew(entry: ringActivity, selectInserted: false)
        }
        let seedData = self.assetRepository.getSeedEvents()
        let now = Date()
        for e in seedData {
            let compare = Calendar.current.compare(now, to: e.eventDate, toGranularity: .day)
            if compare == .orderedDescending {
                let _ = self.eventRepository.insertNew(entry: e, selectInserted: false)
            }
        }
        
        let activityFunction = self.getRandomActivity(allactivities: allactivities, canFavorite: canFavorites)
        for dayOfWeek in DayOfWeek.allCases {
            if dayOfWeek != .None {
                for index in 0..<6 {
                    let activity = activityFunction()
                    let dailyWorkout = DailyWorkOut(dailyWorkOutId: UUID(), dayOfWeek: dayOfWeek, activitySource: activity.activitySource, order: index, name: "")
                    let _ = dailyWorkoutRepository.insertNew(entry: dailyWorkout, selectInserted: false)
                }
            }
        }
    }
    
    func getRandomActivity(allactivities:[RingFitActivity], canFavorite:[UUID: Bool]) -> randomFunction {
        var previousValues = [Int: Int]()
        let function:randomFunction =  {
            let max = allactivities.count - 1
            var randomInt = Int.random(in: 1..<max)
            var isAlowed = canFavorite[allactivities[randomInt].categoryId] ?? false
            while previousValues[randomInt] != nil || !(isAlowed) {
                randomInt = Int.random(in: 1..<max)
                isAlowed = canFavorite[allactivities[randomInt].categoryId] ?? false
            }
            let activity = allactivities[randomInt]
            previousValues[randomInt] = randomInt
            return activity
        }
        return function
    }
}
