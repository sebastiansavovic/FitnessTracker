//
//  SettingsViewController.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 2/27/21.
//

import UIKit

class SettingsViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var leftImage: UIImageView!
    @IBOutlet weak var rightImage: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet var swipLeft: UISwipeGestureRecognizer!
    @IBOutlet weak var dailyWorkoutTable: UITableView!
    @Dependency(DailyWorkoutRepository.self) var dailyWorkoutRepository:DailyWorkoutRepository
    @Dependency(AssetRepository.self) var assetRepository: AssetRepository
    let cellReuseIdentifier = "workoutCell"
    var currentDay:DayOfWeek = .Monday
    var workouts:[DailyWorkOut] = [DailyWorkOut]()
    let segueId = "showActivityDetails"
    var selectedCell:IndexPath? = nil
    var ringActivities:[RingFitActivity] = [RingFitActivity]()
    var leftIndex = 0
    var midIndex = 1
    var rightIndex = 2
    var isEdit = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.editButton.layer.cornerRadius = 4
        self.image.isUserInteractionEnabled = true
        self.workouts = self.dailyWorkoutRepository.getActivitiesForDay(dayOfWeek: self.currentDay)
        self.dailyWorkoutTable.delegate = self
        self.dailyWorkoutTable.dataSource = self
        self.ringActivities = self.assetRepository.getSelectableRingFitActivities()
        self.leftImage.image = self.ringActivities[self.leftIndex].getIcon()
        self.image.image = self.ringActivities[self.midIndex].getIcon()
        self.rightImage.image = self.ringActivities[self.rightIndex].getIcon()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let target = segue.destination as? LibraryDetailViewController {
            if let i = self.selectedCell {
                let workout = self.workouts[i.row]
                let ringActivity = self.assetRepository.getRingActivityById(id: workout.activitySource)
                target.ringFitActivity = ringActivity
            }
        }
        
    }

    @IBAction func editTapped(_ sender: UIButton) {
        self.isEdit = !self.isEdit
        let title = self.isEdit ? "Done" : "Edit"
        self.dailyWorkoutTable.isEditing = self.isEdit
        self.editButton.setTitle(title, for: .normal)
    }
    
    
    @IBAction func dayChanged(_ sender: UISegmentedControl) {
        self.currentDay = indexToDayOfWeek(index: sender.selectedSegmentIndex)
        self.reloadData()
        
    }
    
    @IBAction func swipe(_ sender: UISwipeGestureRecognizer) {
        let rightRect = self.rightImage.frame
        let leftRect = self.leftImage.frame
        let middleRect = self.image.frame
        let bottomRect = middleRect.offsetBy(dx: 0, dy: 50)
        switch sender.direction {
        case .right:
            self.rightIndex = self.rightIndex == 0 ? self.ringActivities.count - 1 : (self.rightIndex - 1)
            self.midIndex = self.midIndex == 0 ? self.ringActivities.count - 1 : (self.midIndex - 1)
            self.leftIndex = self.leftIndex == 0 ? self.ringActivities.count - 1 : (self.leftIndex - 1)
            UIView.animateKeyframes(withDuration: 1.0, delay: 0, options: .calculationModeCubic, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3, animations: {
                    self.rightImage.isHidden = true
                    self.image.frame = rightRect
                    self.leftImage.frame = middleRect
                })
                UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.0, animations: {
                    self.rightImage.frame = leftRect
                })
                UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.1, animations: {
                    self.rightImage.isHidden = false
                    self.rightImage.image = self.ringActivities[self.leftIndex].getIcon()
                })
            }, completion: {
                finished in
                self.image.image = self.ringActivities[self.midIndex].getIcon()
                self.rightImage.image = self.ringActivities[self.rightIndex].getIcon()
                self.leftImage.image = self.ringActivities[self.leftIndex].getIcon()
            })
        case .down:
            UIView.animateKeyframes(withDuration: 1.0, delay: 0.3, options: .calculationModeCubic, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
                    self.image.frame = bottomRect
                })
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.0, animations: {
                    self.image.isHidden = true
                })
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5, animations: {
                    self.image.frame = middleRect
                })
                UIView.addKeyframe(withRelativeStartTime: 1.0, relativeDuration: 0.5, animations: {
                    self.image.isHidden = false
                })
            }, completion: {
                finished in
                let targetSource = self.ringActivities[self.midIndex].activitySource
                if let _ = self.workouts.first(where: {
                    $0.activitySource == targetSource
                })
                {
                    let alert = UIAlertController(title: "warning", message: "Activity has already been added", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "ok", style: .default, handler: {
                        (action) ->  Void in
                    })
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                }
                else  if self.workouts.count > 9 {
                    let alert = UIAlertController(title: "warning", message: "Cannot add more than 10 activities per day", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "ok", style: .default, handler: {
                        (action) ->  Void in
                    })
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    let order = self.workouts.count + 1
                    let newDailyWorkout = DailyWorkOut(dailyWorkOutId: UUID(), dayOfWeek: self.currentDay, activitySource: targetSource, order: order, name: "")
                    let _ = self.dailyWorkoutRepository.insertNew(entry: newDailyWorkout, selectInserted: false)
                    self.reloadData()
                }
            })
        case .left:
            self.rightIndex = (self.rightIndex + 1) % self.ringActivities.count
            self.midIndex = (self.midIndex + 1) % self.ringActivities.count
            self.leftIndex = (self.leftIndex + 1) % self.ringActivities.count
            UIView.animateKeyframes(withDuration: 1.0, delay: 0, options: .calculationModeCubic, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3, animations: {
                    self.leftImage.isHidden = true
                    self.image.frame = leftRect
                    self.rightImage.frame = middleRect
                })
                UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.0, animations: {
                    self.leftImage.frame = rightRect
                })
                UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.1, animations: {
                    self.leftImage.isHidden = false
                    self.leftImage.image = self.ringActivities[self.rightIndex].getIcon()
                })
            }, completion: {
                finished in
                self.image.image = self.ringActivities[self.midIndex].getIcon()
                self.rightImage.image = self.ringActivities[self.rightIndex].getIcon()
                self.leftImage.image = self.ringActivities[self.leftIndex].getIcon()
            })
        default:
            break
        }
    }

    private func reloadData() {
        self.workouts = self.dailyWorkoutRepository.getActivitiesForDay(dayOfWeek: self.currentDay)
        dailyWorkoutTable.reloadData()
    }
    /// needed due to my desire to have the left most item be monday
    private func indexToDayOfWeek(index: Int) -> DayOfWeek {
        if index == 6 {
            return .Sunday
        }
        let day = index + 2
        return DayOfWeek(rawValue: Int64(day))!
    }
    
    private func generateEditButton(_ indexPath: IndexPath) -> UISwipeActionsConfiguration {
        let editAction = UIContextualAction(style: .normal, title: "delete", handler: {
            (contextualAction, view, success) in
            let localItem = self.workouts[indexPath.row]
            
            let _ = self.dailyWorkoutRepository.deleteById(id: localItem.dailyWorkOutId)
            self.workouts.remove(at: indexPath.row)
            self.dailyWorkoutTable.deleteRows(at: [indexPath], with: .fade)
            
            success(true)
        })
        editAction.backgroundColor = .red
        let swipeActions = UISwipeActionsConfiguration(actions: [editAction])
        return swipeActions
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let oldObject = self.workouts[destinationIndexPath.row]
        let movedObject = self.workouts[sourceIndexPath.row]
        let update1 = oldObject.cloneShallowWithNewOrder(order: movedObject.order)
        let update2 = movedObject.cloneShallowWithNewOrder(order: oldObject.order)
        let _ = self.dailyWorkoutRepository.update(entry: update1)
        let _ = self.dailyWorkoutRepository.update(entry: update2)
        self.workouts[destinationIndexPath.row] = update2
        self.workouts[sourceIndexPath.row] = update1
    }
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return generateEditButton(indexPath)
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return generateEditButton(indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedCell = indexPath
        self.performSegue(withIdentifier: self.segueId, sender: self)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.dailyWorkoutTable.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        let localWorkout = self.workouts[indexPath.row]
        
        cell.textLabel?.text = localWorkout.name
        cell.imageView?.image = localWorkout.getIcon()
        return cell
    }
}
