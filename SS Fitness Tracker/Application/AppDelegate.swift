//
//  AppDelegate.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 2/21/21.
//

import UIKit
import SQLite



@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private func registerClasses() {
        let assetrepository = AssetRepository()
        let isNew = assetrepository.prepareActivitiesDatabase()
        let dataRespository = DataRepository(assetRepository: assetrepository)
        
        let cacheManager = CacheManager()
        let favoriteRepo = FavoriteRepository(assetRepository: assetrepository)
        let eventRepository = EventRepository(assetRepository: assetrepository)
        let activityRepository = ActivityRepository(assetRepository: assetrepository)
        let ringActivityRepository = RingActivityRepository(assetRepository: assetrepository)
        let dailyWorkoutRepository = DailyWorkoutRepository(assetRepository: assetrepository)
        Resolver.register(DataRepository.self, value:dataRespository)
        Resolver.register(AssetRepository.self, value:assetrepository)
        Resolver.register(CacheManager.self, value: cacheManager)
        Resolver.register(EventRepository.self, value: eventRepository)
        Resolver.register(ActivityRepository.self, value: activityRepository)
        Resolver.register(ImageAnalyzer.self, value: ImageAnalyzer())
        Resolver.register(FavoriteRepository.self, value: favoriteRepo)
        Resolver.register(RingActivityRepository.self, value: ringActivityRepository)
        Resolver.register(DailyWorkoutRepository.self, value: dailyWorkoutRepository)
        if isNew {
            dataRespository.insertSeedData()
        }
    }
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.registerClasses()
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    
}

