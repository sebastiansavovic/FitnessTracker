//
//  LibraryDetailViewController.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/6/21.
//

import Foundation
import UIKit


class LibraryDetailViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    
    @Dependency(AssetRepository.self) var assetRepository:AssetRepository
    @Dependency(ActivityRepository.self) var activityRepository:ActivityRepository
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var activitiesTable: UITableView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var detailsText: UITextView!
    @IBOutlet weak var editButton: UIButton!
    
    var ringFitActivity: RingFitActivity? = nil
    let cellReuseIdentifier = "activityCell"
    let editCellIndentifier = "EditCell"
    var activities: [ActivityWithDateDto] = [ActivityWithDateDto]()
    let editContext: EditContext<ActivityWithDateDto> = EditContext<ActivityWithDateDto>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let activity = ringFitActivity {
            self.titleLabel.text = activity.name
            self.activities = activityRepository.getActivitiesByActivityId(id: activity.activitySource, name: activity.name)
            
            if let icon = activity.getIcon() {
                self.iconImage.image = icon
            }
            
            let sum = self.activities.reduce(0, {
                (result, a) in
                return a.value + result
            })
            
            let category = self.assetRepository.getRingFitCategories().filter({ $0.categoryId == activity.categoryId }).first!
            let html = activity.toHtml(category: category.name, sum: sum)
            let data = Data(html.utf8)
            
            if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                detailsText.attributedText = attributedString
            }
        }
        self.activitiesTable.dataSource = self
        self.activitiesTable.delegate = self
        self.editButton.layer.cornerRadius = 4
        self.editButton.isEnabled = false
        self.editButton.backgroundColor = .gray
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIWindow.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIWindow.keyboardWillHideNotification, object: nil)
        let tap = UITapGestureRecognizer(target:self,
                                         action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
    }
    private func setViewMovedUp(movedUp: Bool, offset:CGFloat) {
        UIView.animate(withDuration: 0.1, animations: {
            var rect = self.view.frame
            if movedUp {
                rect.origin.y -=  offset;
            }
            else {
                rect.origin.y +=  offset;
            }
            self.view.frame = rect;
        })
    }
    private func getKeyBoardHeight(notification: NSNotification) -> CGFloat {
        var offset = CGFloat(0.0)
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            offset = keyboardRectangle.height
        }
        return offset
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let offset = self.getKeyBoardHeight(notification: notification)
        let currentPosition = self.view.frame.origin.y
        if currentPosition >= 0 {
            self.setViewMovedUp(movedUp: true, offset: offset)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        let offset = self.getKeyBoardHeight(notification: notification)
        let currentPosition = self.view.frame.origin.y
        if currentPosition < 0 {
            self.setViewMovedUp(movedUp: false, offset: offset)
        }
    }
    
    fileprivate func saveRecord(_ updateValue: ActivityWithDateDto, _ index: IndexPath) {
        let oldActivity = activityRepository.getById(id: updateValue.activityId)!
        let newActivity = oldActivity.cloneWithNewValue(newValue: updateValue.value)
        let _ = activityRepository.update(entry: newActivity)
        self.activities[index.row] = updateValue
        self.editContext.removeFromContext(id: index)
    }
    
    @IBAction func editPressed(_ sender: UIButton) {
        var indexesToUpdate = [IndexPath]()
        for updated in self.editContext.getAllEditedItems() {
            let index = updated.0
            indexesToUpdate.append(index)
            let updateValue = updated.1
            saveRecord(updateValue, index)
        }
        for key in self.editContext.getAllUnEditedIndexes() {
            self.editContext.removeFromContext(id: key)
            indexesToUpdate.append(key)
        }
        self.activitiesTable.reloadRows(at: indexesToUpdate, with: .left)
        self.editButton.isEnabled = false
        self.editButton.backgroundColor = .gray
    }
    
    
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let title = "delete"
        let favotireAction = UIContextualAction(style: .destructive, title: title, handler: {
            (contextualAction, view, success) in
            MyLog.debug("Will delete row \(indexPath.row)")
            success(true)
            
        })
        let swipeActions = UISwipeActionsConfiguration(actions: [favotireAction])
        return swipeActions
    }
  
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var action:UIContextualAction? = nil
        if self.editContext.isEditingAtRow(index: indexPath){
            action = UIContextualAction(style: .normal, title: "save", handler: {
                (contextualAction, view, success) in
                if let newActivity = self.editContext.getEditValueAtRow(index: indexPath) {
                    self.saveRecord(newActivity, indexPath)
                }
                else {
                    self.editContext.removeFromContext(id: indexPath)
                }
                self.activitiesTable.reloadRows(at: [indexPath], with: .left)
                if  self.editContext.isEmpty() {
                    self.editButton.isEnabled = false
                    self.editButton.backgroundColor = .gray
                }
                success(true)
                
            })
        }
        else {
            action = UIContextualAction(style: .normal, title: "edit", handler: {
                (contextualAction, view, success) in
                let oldActivity = self.getActivityAtIndex(index: indexPath)
                self.editContext.applyNewEdit(index: indexPath, oldValue: oldActivity, newValue: nil, id: oldActivity.activityId)
                self.activitiesTable.reloadRows(at: [indexPath], with: .right)
                self.editButton.isEnabled = true
                self.editButton.backgroundColor = .blue
                success(true)
                
            })
        }
        if let action = action {
            action.backgroundColor = .blue
            let swipeActions = UISwipeActionsConfiguration(actions: [action])
            return swipeActions
        }
        return nil
    }
    private func getActivityAtIndex(index: IndexPath) -> ActivityWithDateDto {
        return self.activities[index.row]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }
    func activityValueChanged(activity: ActivityWithDateDto, newValue:Int) {
        self.editContext.applyEditByPrimaryKey(id: activity.activityId, newValue: activity.cloneShallowWithNewValue(value: newValue))
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.editContext.isEditingAtRow(index: indexPath) {
            let localActivity = self.editContext.getEditValueAtRow(index: indexPath) ?? self.getActivityAtIndex(index: indexPath)
            let cell = (self.activitiesTable.dequeueReusableCell(withIdentifier: editCellIndentifier) as? ActivityDtoCell)!
            cell.activity = localActivity
            cell.valueChanged = activityValueChanged
       
            return cell
        }
        else {
            let cell = (self.activitiesTable.dequeueReusableCell(withIdentifier: cellReuseIdentifier))!
            let localActivity = activities[indexPath.row]
            cell.textLabel?.text = localActivity.toLineString()
            return cell
        }
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
}
