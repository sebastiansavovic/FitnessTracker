//
//  CurrentDayViewcontroller.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 2/27/21.
//

import UIKit

class AlleventsViewcontroller : UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    @Dependency(EventRepository.self) var eventRepository: EventRepository
    @Dependency(AssetRepository.self) var assetRepository: AssetRepository
    
    
    @IBOutlet weak var eventsTable: UITableView!
    @IBOutlet weak var eventsSearch: UISearchBar!
    
    let cellReuseIdentifier = "ActivityViewCell"
    let sugueId = "eventSegueId"
    var allEvents:[Event] = [Event]()
    var unfilteredEvents:[Event] = [Event]()
    let oneMonth = 0
    let threeMonths = 1
    let sixMonths = 2
    let allMonths = 3
    var eventListener:Any? = nil
    var selectedEvent:Event? = nil
    lazy var monthMapping:[Int: Int] = {
        return [oneMonth: 1,
                threeMonths: 3,
                sixMonths: 6,
                allMonths: 100]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.allEvents = self.eventRepository.getPreviousMonthsEvents(self.monthMapping[oneMonth]!)
        self.unfilteredEvents = self.allEvents
        
        self.eventsTable.dataSource = self
        self.eventsTable.delegate = self
        self.eventsSearch.delegate = self
        self.eventListener = self.eventRepository.registerForEvent(type: [.Inserted], callback: {
            (e,o) in
            self.eventsSearch.selectedScopeButtonIndex = 0
            self.allEvents = self.eventRepository.getPreviousMonthsEvents(self.monthMapping[self.oneMonth]!)
            self.unfilteredEvents = self.allEvents
            self.eventsTable.reloadData()
        })
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? EventsViewController {
            destination.event = self.selectedEvent
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.allEvents.count
    }
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: "delete", handler: {
            (contextualAction, view, success) in
            let localItem = self.allEvents[indexPath.row]
            
            let _ = self.eventRepository.deleteById(id: localItem.eventId)
            self.allEvents.remove(at: indexPath.row)
            self.eventsTable.deleteRows(at: [indexPath], with: .fade)
            
            success(true)
        })
        editAction.backgroundColor = .red
        let swipeActions = UISwipeActionsConfiguration(actions: [editAction])
        return swipeActions
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.eventsTable.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        let localEvent = self.allEvents[indexPath.row]
        cell.textLabel?.text = localEvent.eventDate.toShortDateString()
        if let localActivities = localEvent.activities {
            let text = localActivities.map({
                $0.name ?? ""
            }).joined(separator: ", ")
            cell.detailTextLabel?.text = text
        }
        else {
            cell.detailTextLabel?.text = "No activities"
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedEvent = self.allEvents[indexPath.row]
        self.performSegue(withIdentifier: self.sugueId, sender: self)
    }
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if let months = self.monthMapping[selectedScope] {
            self.unfilteredEvents = self.eventRepository.getPreviousMonthsEvents(months)
        }
        else{
            self.unfilteredEvents = self.eventRepository.getPreviousMonthsEvents(self.monthMapping[oneMonth]!)
        }
        self.applySearch(searchText: self.eventsSearch.text ?? "")
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        self.eventsSearch.showsCancelButton = false
        self.eventsSearch.text = ""
        self.applySearch(searchText: "")
        
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.applySearch(searchText: searchText)
    }
    private func applySearch(searchText: String) {
        if searchText == "" {
            self.allEvents = self.unfilteredEvents
        }
        else {
            self.eventsSearch.showsCancelButton = true
            let localEvents = self.unfilteredEvents.filter({
                (event) -> Bool in
                
                let dateAsString = event.eventDate.toShortDateString()
                if let _ = dateAsString.range(of: searchText, options: .caseInsensitive) {
                    return true
                }
                if let localActivities = event.activities {
                    if let _ = localActivities.first(where: {
                        (a) -> Bool in
                        if let _ = (a.name ?? "").range(of: searchText, options: .caseInsensitive) {
                            return true
                        }
                        return false
                    }) {
                        return true
                    }
                   
                }
                
                return false
            })
            self.allEvents = localEvents
            self.eventsTable.reloadData()
        }
    }
}

