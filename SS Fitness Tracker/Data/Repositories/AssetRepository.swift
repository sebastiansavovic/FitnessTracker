//
//  AssetRepository.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 2/27/21.
//

import Foundation
import UIKit
import SQLite

public class AssetRepository {
    private let acitivityDatabaseAssetName = "AcitivityDatabase"
    private let ringActivitiesAssetName = "RingActivities"
    private let ringSeed = "ActivitiesSeed"
    private let ringFitCategories = "RingFitCategories"
    private let activityLookup:[UUID: RingFitActivity]
    private let categoryLookup:[UUID: RingFitCategory]
    private let activityCategories:[RingFitCategory]
    private let activityIdLookup:[String: UUID]
    private let activities:[RingFitActivity]
    public init(){
        let data =  NSDataAsset(name: ringActivitiesAssetName, bundle: Bundle.main)!.data
        let decoder = JSONDecoder()
        activities = try! decoder.decode([RingFitActivity].self, from: data)
        let map = activities.lazy.map({($0.activitySource, $0) })
        activityLookup = Dictionary(map, uniquingKeysWith: { _, latest in latest })
        let map2 = activities.lazy.map({($0.name, $0.activitySource)})
        activityIdLookup = Dictionary(map2, uniquingKeysWith: { _, latest in latest })
        
        let dataCategories =  NSDataAsset(name: ringFitCategories, bundle: Bundle.main)!.data
        activityCategories = try! decoder.decode([RingFitCategory].self, from: dataCategories)
        let map3 = activityCategories.lazy.map({($0.categoryId, $0)})
        categoryLookup = Dictionary(map3, uniquingKeysWith: { _, latest in latest })
    }
    private func getAssetByName(name: String) -> NSDataAsset {
        if let asset =  NSDataAsset(name: name, bundle: Bundle.main) {
            return asset
        }
        else{
            fatalError("\(name) is not found")
        }
    }
    public func getSqlDb() -> Connection {
        do {
            let path = self.getPathForActivitiesDatabase()
            return try Connection(path)
        }
        catch {
            fatalError("Activities Database not available")
        }
    }
    public func getActivityIdByName(name: String) -> UUID? {
        return self.activityIdLookup[name]
    }
    public func getRingActivityById(id: UUID) -> RingFitActivity {
        return self.activityLookup[id]!
    }
    public func getRingFitActivities() -> [RingFitActivity] {
        return self.activities
    }
    public func getSelectableRingFitActivities() -> [RingFitActivity] {
        return self.activities.filter({
            if let cat = self.categoryLookup[$0.categoryId] {
                return cat.canFavorite
            }
            return false
        })
    }
    public func getRingFitCategories() -> [RingFitCategory] {
        return self.activityCategories
    }
    public func getSeedEvents() -> Array<Event> {
        let asset = getAssetByName(name: self.ringSeed)
        let decoder = JSONDecoder()
        let data = asset.data
        decoder.dateDecodingStrategy = .formatted(Formatter.iso8601)
        return try! decoder.decode(Array<Event>.self, from: data)
    }
    public func getSampleImages() -> SampleActivities {
        let name = "SampleImagesJson"
        let asset = self.getAssetByName(name: name)
        let decoder = JSONDecoder()
        let data = asset.data
        return try! decoder.decode(SampleActivities.self, from: data)
    }
    public func prepareActivitiesDatabase() -> Bool {
        if !self.checkIfUserFileExists(name: self.acitivityDatabaseAssetName){
            do {
                let detination = self.getPathForActivitiesDatabase()
                let source = self.getAssetByName(name: self.acitivityDatabaseAssetName)
                try source.data.write(to: URL(fileURLWithPath: detination))
            }
            catch
            {
                MyLog.debug(error.localizedDescription)
                fatalError("Cannot copy activity database")
            }
            return true
        }
        return false
    }
    public func getPathForActivitiesDatabase() -> String {
        return self.getUserPath(name: self.acitivityDatabaseAssetName)
    }
    private func getUserPath(name: String) -> String {
        let path = self.getDocumentFolder()
        return "\(path)/\(name)"
    }
    private func getDocumentFolder() -> String {
        return NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first!
    }
    private func checkIfUserFileExists(name: String) -> Bool {
        let path = self.getUserPath(name: name)
        do {
            var _ = try Data(contentsOf: URL(fileURLWithPath: path))
            return true
        }
        catch {
            return false
        }
    }
}
