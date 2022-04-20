//
//  LibraryViewController.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/5/21.
//

import Foundation
import UIKit

class LibraryViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    
    @IBOutlet weak var activityTable: UITableView!
    @IBOutlet weak var activitySearch: UISearchBar!
    
    @Dependency(FavoriteRepository.self) var favoriteRepository:FavoriteRepository
    @Dependency(AssetRepository.self) var assetRepository:AssetRepository
    @Dependency(ActivityRepository.self) var activityRepository:ActivityRepository
    
    let cellReuseIdentifier = "libraryCell"
    let sugueId = "libraryDetailSegue"
    var searchActive : Bool = false
    var favorites:[UUID: FavoriteType] = [UUID: FavoriteType]()
    var categories:[RingFitCategory] = [RingFitCategory]()
    var activities:[UUID:[RingFitActivity]] = [UUID:[RingFitActivity]]()
    var allActivities:[RingFitActivity] = [RingFitActivity]()
    var selectedCell:LibraryDetailCell? = nil
    var activititesAggregate:[UUID: ActivityAggregateDto] = [UUID: ActivityAggregateDto]()
    
    private let favoriteIndex = 1
    private let itemsWithReps = 2
    private let itemsIgnored = 3
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.allActivities = self.assetRepository.getRingFitActivities()
        self.categories = self.assetRepository.getRingFitCategories()
        applyGroups(filtered: allActivities)
        activityTable.dataSource = self
        activityTable.delegate = self
        activitySearch.delegate = self
        let favItems = favoriteRepository.getAll()
        for favItem in favItems {
            self.favorites[favItem.activitySource] = favItem.type
        }
        activititesAggregate = self.activityRepository.getAggreateActivities().reduce(into: [UUID: ActivityAggregateDto](), { $0[$1.activitySource] = $1 })
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIWindow.keyboardDidShowNotification, object: nil)
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? LibraryDetailViewController {
            if let cell = selectedCell {
                destination.ringFitActivity = cell.ringFitActivity
            }
        }
    }
    @objc func keyboardWillShow(notification: NSNotification) {
        self.activitySearch.showsCancelButton = true
    }
    
    private func applyGroups(filtered: [RingFitActivity]) {
        activities = Dictionary(grouping: filtered, by: { $0.categoryId })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return categories.count
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < categories.count {
            return categories[section].name
        }
        return nil
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let id = categories[section].categoryId
        return activities[id]?.count ?? 0
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .insert
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (self.activityTable.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! LibraryDetailCell?)! //as! UITableViewCell?
        let localActivity = findActivityByIndex(index: indexPath)
        let sum = activititesAggregate[localActivity.activitySource]?.sum ?? 0
        cell.textLabel?.text = "\(localActivity.name) (\(sum))"
        cell.ringFitActivity = localActivity
        cell.detailTextLabel?.text = localActivity.hashTags?.joined(separator: ", ")
        if let icon = localActivity.getIcon()?.copy(newSize: CGSize(width: 40, height: 40)) {
            cell.imageView?.image = icon
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedCell = tableView.cellForRow(at: indexPath) as? LibraryDetailCell
        self.performSegue(withIdentifier: self.sugueId, sender: self)
    }
    private func findActivityByIndex(index: IndexPath) -> RingFitActivity {
        let id = self.categories[index.section].categoryId
        return self.activities[id]![index.row]
    }
    func removeRowIfNeeded(indexPath: IndexPath, target: FavoriteType, isReplace: Bool) {
        let selectedId = self.activitySearch.selectedScopeButtonIndex
        var remove = false
        if isReplace {
            if  (selectedId == self.itemsIgnored &&
                    target == .Favorite) ||
                    (selectedId == self.favoriteIndex &&
                        target == .Ignore) {
                remove = true
            }
            
        }
        else {
            if  (selectedId == self.favoriteIndex &&
                    target == .Favorite) ||
                    (selectedId == self.itemsIgnored &&
                        target == .Ignore) {
                remove = true
            }
        }
        if remove {
            let category = self.categories[indexPath.section]
            self.activities[category.categoryId]?.remove(at: indexPath.row)
            self.activityTable.deleteRows(at: [indexPath], with: .fade)
        }
    }
    fileprivate func GenerateFavoriteSideButton(_ indexPath: IndexPath, target: FavoriteType) -> UISwipeActionsConfiguration? {
        let activity = self.findActivityByIndex(index: indexPath)
        let category = self.categories[indexPath.section]
        if !category.canFavorite {
            return nil
        }
        var color:UIColor = .blue
        var title = "Favorite"
        if target == .Ignore {
            title = "Ingore"
            color = .gray
        }
        var currentType = FavoriteType.None
        
        if let type = self.favorites[activity.activitySource] {
            if type == target {
                title = "Un\(title)"
                color = .red
            }
            currentType = type
        }
        let favotireAction = UIContextualAction(style: .normal, title: title, handler: {
            (contextualAction, view, success) in
            if(currentType == target){
                self.favorites.removeValue(forKey: activity.activitySource)
                let _ = self.favoriteRepository.deleteById(id: activity.activitySource)
                self.removeRowIfNeeded(indexPath: indexPath, target: target, isReplace: false)
            }
            else{
                if currentType != target && currentType != .None {
                    let _ = self.favoriteRepository.deleteById(id: activity.activitySource)
                    self.removeRowIfNeeded(indexPath: indexPath, target: target, isReplace: true)
                }
                self.favorites[activity.activitySource] = target
                let favItem = Favorites(activitySource: activity.activitySource, type: target)
                let _ = self.favoriteRepository.insertNew(entry: favItem, selectInserted: false)
            }
            //            self.activityTable.reloadData()
            success(true)
            
        })
        favotireAction.backgroundColor = color
        let swipeActions = UISwipeActionsConfiguration(actions: [favotireAction])
        return swipeActions
    }
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return GenerateFavoriteSideButton(indexPath, target: .Ignore)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return GenerateFavoriteSideButton(indexPath, target: .Favorite)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        self.activitySearch.showsCancelButton = false
    }
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        var localActivities = self.allActivities
        switch(selectedScope) {
        case self.favoriteIndex:
            localActivities = localActivities.filter({
                (activity) in
                if let a = self.favorites[activity.activitySource] {
                    return a == .Favorite
                }
                return false
            })
        case self.itemsWithReps:
            localActivities = localActivities.filter({
                (activity) in
                if let a = self.activititesAggregate[activity.activitySource] {
                    return a.sum > 0
                }
                return false
            })
        case self.itemsIgnored: //ignored
            localActivities = localActivities.filter({
                (activity) in
                if let a = self.favorites[activity.activitySource] {
                    return a == .Ignore
                }
                return false
            })
        default:
            localActivities = self.allActivities
        }
        self.applySearch(searchText: searchBar.text ?? "", baseActivities: localActivities)
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        self.activitySearch.showsCancelButton = false
        self.activitySearch.text = ""
        self.applyGroups(filtered: self.allActivities)
        
    }
    private func applySearch(searchText: String, baseActivities:[RingFitActivity]) {
        if searchText == "" {
            self.applyGroups(filtered: baseActivities)
        }
        else {
            self.activitySearch.showsCancelButton = true
            let activitiesLocal = baseActivities.filter({
                (text) -> Bool in
                
                let allTags = text.hashTags?.joined(separator: ", ") ?? ""
                
                if let _ = allTags.range(of: searchText, options: .caseInsensitive) {
                    return true
                }
                
                if let _ = text.name.range(of: searchText, options: .caseInsensitive) {
                    return true
                }
                
                
                return false
            })
            self.applyGroups(filtered: activitiesLocal)
        }
        self.activityTable.reloadData()
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.applySearch(searchText: searchText, baseActivities: allActivities)
    }
}


