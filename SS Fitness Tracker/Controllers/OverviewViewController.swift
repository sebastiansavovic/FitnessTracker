//
//  ViewController.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 2/21/21.
//

import UIKit
import SQLite
import VisionKit
import Vision


class OverviewViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let cellReuseIdentifier = "aggregateCell"
    @IBOutlet weak var aggregateTable: UITableView!
    @IBOutlet weak var addActivityButton: ButtonWithImage!
    @IBOutlet weak var recentActivityChart: RecentActivityChart!
    @Dependency(ImageAnalyzer.self)var imageAnalyzer:ImageAnalyzer
    @Dependency(DataRepository.self)var dataRepository:DataRepository
    @Dependency(AssetRepository.self)var assetRepository:AssetRepository
    @Dependency(EventRepository.self)var eventRepository:EventRepository
    @Dependency(ActivityRepository.self)var activityRepository:ActivityRepository
    @Dependency(FavoriteRepository.self) var favoriteRepository:FavoriteRepository
    @Dependency(DailyWorkoutRepository.self) var dailyWorkoutRepository:DailyWorkoutRepository
    let segueId = "imageSelected"
    var selectedActivity:ActivityAggregateDto?
    var favListener:Any? = nil
    var workoutListener:Any? = nil
    var eventListener:Any? = nil
    var top5Ids:[UUID] = [UUID]()
    var least5Ids:[UUID] = [UUID]()
    var todayIds:[UUID] = [UUID]()
    let todaysActivities = 0
    let top5Activities = 1
    let bottom5Activities = 2
    let newEventSugue = "newEventSugue"
    var event:Event?
    
    
    lazy var aggregateData: [Int:[ActivityAggregateDto]] = {
        let _sections = [self.todaysActivities: [ActivityAggregateDto](),
                         self.top5Activities: [ActivityAggregateDto](),
                         self.bottom5Activities: [ActivityAggregateDto]()]
        return _sections
    }()
    lazy var spinner:UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.center = CGPoint(x: 130, y: 65)
        spinner.color = .black
        return spinner
    }()

    lazy var sectionNames:[Int: String] = {
        let _sections = [self.todaysActivities: "Today's Activities",
                         self.top5Activities: "Top 5 Activities",
                         self.bottom5Activities: "Least used activities"]
        return _sections
    }()
    lazy var sectionNoRowsRow:[Int: String] = {
        let _sections = [self.todaysActivities: "Rest Day",
                         self.top5Activities: "No Data",
                         self.bottom5Activities: "No Data"]
        return _sections
    }()
    
    lazy var alert:UIAlertController = {
        let title = "loading"
        let message = "\n\n\n"
        let alert =  UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.addSubview(self.spinner)
        return alert
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.aggregateTable.dataSource = self
        self.aggregateTable.delegate = self
        self.addActivityButton.backgroundColor = .red
        self.addActivityButton.layer.cornerRadius = 4
        
        let activities = self.eventRepository.getEventsFromLastWeek()
        recentActivityChart.setChart(dataPoints: activities)
        recreateTop5()
        recreateLeast5()
        recreateTodaysActivities()
        
        
        
        favListener = self.favoriteRepository.registerForEvent(type: [.Inserted, .Deleted], callback: {
            (o, id) in
            if o == .Deleted {
                self.recreateTop5()
                self.recreateLeast5()
                self.aggregateTable.reloadData()
            }
            if let fav = self.favoriteRepository.getById(id: id) {
                if fav.type == .Ignore {
                    var reload = false
                    if let _  = self.top5Ids.first(where: {
                        $0 == id
                    }) {
                        reload = true
                        self.recreateTop5()
                    }
                    if let _  = self.least5Ids.first(where: {
                        $0 == id
                    }) {
                        reload = true
                        self.recreateLeast5()
                    }
                    if reload {
                        self.aggregateTable.reloadData()
                    }
                    else {
                        MyLog.debug("Wil not reload")
                    }
                }
            }
        })
        eventListener = self.eventRepository.registerForEvent(type: [.Inserted,.Deleted], callback: {
            (o, id) in
            let localActivities = self.eventRepository.getEventsFromLastWeek()
            
            self.recentActivityChart.setChart(dataPoints: localActivities)
        })
        workoutListener =  self.dailyWorkoutRepository.registerForEvent(type: [.Inserted, .Updated, .Deleted], callback: {
            (o, id) in
            self.recreateTodaysActivities()
            
            self.aggregateTable.reloadSections([self.todaysActivities], with: .automatic)
        })
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let target = segue.destination as? ImageSelectorViewController {
            target.imageSelected = imageWasSelected
        }
        else if let target = segue.destination as? LibraryDetailViewController {
            let ringActivity = self.assetRepository.getRingActivityById(id: selectedActivity!.activitySource)
            target.ringFitActivity = ringActivity
        }
        else if let target = segue.destination as? EventsViewController {
            target.event = event
            target.isNew = true
        }
        
    }
    func recreateTodaysActivities() {
        todayIds = [UUID]()
        let todayActivities = self.activityRepository.getAggregateDailyWorkout()
        for e in todayActivities {
            todayIds.append(e.activitySource)
        }
        self.aggregateData[self.todaysActivities] = todayActivities
    }
    func recreateLeast5() {
        least5Ids = [UUID]()
        let leastactivities = self.activityRepository.getLeastUsedActivities()
        for e in leastactivities {
            least5Ids.append(e.activitySource)
        }
        self.aggregateData[self.bottom5Activities] = leastactivities
    }
    func recreateTop5() {
        top5Ids = [UUID]()
        let topactivities = self.activityRepository.getTop5Activities()
        for e in topactivities {
            top5Ids.append(e.activitySource)
        }
        self.aggregateData[self.top5Activities] = topactivities
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionNames[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rowCount = aggregateData[section]?.count ?? 0
        return rowCount == 0 ? 1 : rowCount
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let localActivity = self.findActivityByIndex(index: indexPath)
        selectedActivity = localActivity
        self.performSegue(withIdentifier: self.segueId, sender: self)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.aggregateTable.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        let rowCount = self.aggregateData[indexPath.section]?.count ?? 0
        if rowCount == 0 {
            cell.textLabel?.text = self.sectionNoRowsRow[indexPath.section] ?? "No Data"
            cell.imageView?.image = nil
        }
        else {
            let localActivity = findActivityByIndex(index: indexPath)
            
            cell.textLabel?.text = "\(localActivity.activityName) (\(localActivity.sum))"
            
            
            if let icon = localActivity.getIcon()?.copy(newSize: CGSize(width: 40, height: 40)) {
                cell.imageView?.image = icon
            }
        }
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return aggregateData.count
    }
    
    func findActivityByIndex(index: IndexPath) -> ActivityAggregateDto {
        return self.aggregateData[index.section]![index.row]
    }
    
    
    

    
    func imageWasSelected(image: SampleActivity){
        self.present(self.alert, animated: true, completion: nil)
        self.spinner.startAnimating()
        self.imageAnalyzer.analyzeSummaryData(images: image, processResults: imageAnalysisCompleted)
    }
    func imageAnalysisCompleted(event: Event) {
        self.alert.dismiss(animated: true, completion: {
            self.spinner.stopAnimating()
            self.event = event
            self.performSegue(withIdentifier: self.newEventSugue, sender: self)
        })
        
    }
}




