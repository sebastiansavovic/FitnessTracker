//
//  EventsViewController.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/8/21.
//

import UIKit

class EventsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var eventDetails: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var activitiesTable: UITableView!
    @IBOutlet weak var saveBtn: UIButton!
    
 
    @Dependency(AssetRepository.self) var assetRepository: AssetRepository
    @Dependency(EventRepository.self) var eventRepository: EventRepository
    @Dependency(ActivityRepository.self) var activityRepository: ActivityRepository
    
    let cellReuseIdentifier = "normalCell"
    let editCell = "editCell"
    var event:Event? = nil
    var isNew:Bool = false
    var allActivities:[Activity] = [Activity]()
    var allRingActivities:[RingFitActivity] = [RingFitActivity]()
    var  ringActivityFinder:[UUID: RingFitActivity] = [UUID: RingFitActivity]()
    let editContext: EditContext<Activity> = EditContext<Activity>()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadData()
        activitiesTable.dataSource = self
        activitiesTable.delegate = self
        
    }
    
    @IBAction func saveNewItem(_ sender: Any) {
        if let event = self.event {
            let newEvent = self.eventRepository.insertNew(entry: event, selectInserted: true)
            self.event = newEvent
            self.isNew = false
            self.editContext.clear()
            self.reloadData()
            self.activitiesTable.reloadData()
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.allActivities.count
    }
    fileprivate func generateEditButton(_ indexPath: IndexPath, isleading: Bool) -> UISwipeActionsConfiguration? {
        if self.isNew {
            return nil
        }
        var title = "edit"
        var color:UIColor = .blue
        var isEdit = false
        var animation = UITableView.RowAnimation.right
        if self.editContext.isEditingAtRow(index: indexPath){
            title = "save"
            if isleading {
                title = "cancel"
            }
            color = .red
            isEdit = true
            animation = .left
        }
        let currentValue = self.allActivities[indexPath.row]
        let editAction = UIContextualAction(style: .normal, title: title, handler: {
            (contextualAction, view, success) in
            MyLog.debug("action will happen")
            if isEdit {
                if !isleading {
                    if let newActivity = self.editContext.getEditValueAtRow(index: indexPath) {
                        let updated = self.activityRepository.update(entry: newActivity)
                        self.allActivities[indexPath.row] = updated
                    }
                    else {
                        MyLog.debug("cannot save activity")
                    }
                }
                
                self.editContext.removeFromContext(id: indexPath)
                self.activitiesTable.reloadRows(at: [indexPath], with: .fade)
            }
            else {
                self.editContext.applyNewEdit(index: indexPath, oldValue: currentValue, newValue: nil, id: currentValue.activityId)
                self.activitiesTable.reloadRows(at: [indexPath], with: animation)
            }
            success(true)
        })
        editAction.backgroundColor = color
        let swipeActions = UISwipeActionsConfiguration(actions: [editAction])
        return swipeActions
    }
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return generateEditButton(indexPath, isleading: true)
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return generateEditButton(indexPath, isleading: false)
    }
    
    func showHandler(alert: UIAlertController, completion: @escaping () -> Void) {
        self.present(alert, animated: true, completion: completion)
    }
    func editChanged(newValue: Activity) {
        self.editContext.applyEditByPrimaryKey(id: newValue.activityId, newValue: newValue)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let localActivity = self.allActivities[indexPath.row]
        
        if self.editContext.isEditingAtRow(index: indexPath) {
            let cell = (self.activitiesTable.dequeueReusableCell(withIdentifier: editCell) as? ActivityCell)!
            cell.action = showHandler
            cell.activities = allRingActivities.filter({
                a in
                if a.activitySource == localActivity.activitySource {
                    return true
                }
                let values = self.allActivities.filter({
                    e in
                    e.activitySource == a.activitySource
                })
                return values.count == 0
            })
            cell.activity = localActivity
            cell.valueChanged = editChanged
            return cell
        }
        else {
            let cell = self.activitiesTable.dequeueReusableCell(withIdentifier: cellReuseIdentifier)! 
            
            let sum = localActivity.value
            cell.textLabel?.text = "\(localActivity.name ?? "") (\(sum))"
            if let ringActivity = self.ringActivityFinder[localActivity.activitySource] {
                cell.detailTextLabel?.text = ringActivity.hashTags?.joined(separator: ", ")
                if let icon = ringActivity.getIcon()?.copy(newSize: CGSize(width: 40, height: 40)) {
                    cell.imageView?.image = icon
                }
            }
            return cell
        }
    }
    fileprivate func reloadData() {
        if let event = self.event {
            titleLabel.text = event.eventDate.toShortDateString()
            
            var hashTags = Set<String>()
            
            if let activities = event.activities{
                self.allActivities = activities
                for a in activities {
                    let rA = self.assetRepository.getRingActivityById(id: a.activitySource)
                    for hashTag in rA.hashTags ?? [String]() {
                        hashTags.insert(hashTag)
                    }
                }
            }
            //maybe redundant, but when editing values into a different type this is easier
            self.allRingActivities = self.assetRepository.getRingFitActivities()
            for ringActivity in allRingActivities {
                self.ringActivityFinder[ringActivity.activitySource] = ringActivity
            }
            
            if self.isNew {
                var i = 0
                for act in event.activities ?? [] {
                    self.editContext.applyNew(index: IndexPath(row: i, section: 0), newValue: act, id: act.activityId)
                    i = i + 1
                }
            }
            else {
                self.saveBtn.isHidden = true
            }
            
            let html = event.toHtml(hashTags: hashTags.sorted().map({$0}))
            let data = Data(html.utf8)
            
            if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                self.eventDetails.attributedText = attributedString
            }
        }
    }
    
}
