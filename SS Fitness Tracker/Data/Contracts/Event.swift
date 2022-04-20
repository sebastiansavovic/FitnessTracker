//
//  Event.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 2/27/21.
//

import Foundation
import SQLite

// MARK: - Event
public class Event: Contract, Codable {
    public typealias T = Event
    public let eventId: UUID
    public let eventDate: Date
    public let caloriesBurned, durationInMinutes: Int
    public var activities: [Activity]?
    
    enum CodingKeys: String, CodingKey {
        case eventId = "EventId"
        case eventDate = "EventDate"
        case caloriesBurned = "CaloriesBurned"
        case durationInMinutes = "DurationInMinutes"
        case activities = "Activities"
    }
    
    public init(eventId: UUID, eventDate: Date, caloriesBurned: Int, durationInMinutes: Int, activities: [Activity]?) {
        self.eventId = eventId
        self.eventDate = eventDate
        self.caloriesBurned = caloriesBurned
        self.durationInMinutes = durationInMinutes
        self.activities = activities
    }
    public func getPrimaryId() -> UUID {
        return self.eventId
    }
    public func cloneShallowWithNewParentId(id: UUID) -> Event {
        return Event(eventId: self.eventId, eventDate: self.eventDate, caloriesBurned: self.caloriesBurned, durationInMinutes: self.durationInMinutes, activities: self.activities)
    }
    public func toHtml(hashTags:[String]) -> String {
      let hashtagString = hashTags.joined(separator: ", ")
        return """
            <html><head><meta http-equiv='Content-Type' content='text/html;charset=windows-1252'>
                <style>
                      table td{
                          min-width: 50px !important;
                          height: 50px !important;
                          font-size:large;
                          border: 0px;
                          border-style: solid;
                      }
                      div{
                          font-size:large;
                          padding-right:10px;
                      }
                  </style>
                  </head>
                  <body>
                      <div>

                            <div style='margin-left: 30px;''>
                            <table>
                              <tr>
                               <td> Calories Burned: </td><td> \(self.caloriesBurned)</td>
                              </tr>
                              <tr>
                                 <td> Duration: </td><td> \(self.durationInMinutes)</td>
                              </tr>
                              <tr>
                                <td>Number of Activities:</td><td> \(self.activities?.count ?? 0)</td>
                              </tr>
                             <tr>
                                <td colspan='2'> Hash tags: </td>
                            </tr>
                             <tr>
                               <td colspan='2'>\(hashtagString)</td>
                            </tr>
                            </table>
                          </div>
                      </div>
                  </body>
                </html>

            """
    }
}

class SqlEventColumns : SqlColumnProtocol {
    typealias T = Event
    var table:Table = Table("Event")
    let eventId = Expression<UUID>("EventId")
    let eventDate = Expression<Date>("EventDate")
    let caloriesBurned = Expression<Int>("CaloriesBurned")
    let durationInMinutes = Expression<Int>("DurationInMinutes")

    func insert(entryId: UUID, entry: Event) -> Insert {

        return self.table.insert(self.eventId <- entryId,
                                  self.caloriesBurned <- entry.caloriesBurned,
                                  self.durationInMinutes <- entry.durationInMinutes,
                                  self.eventDate <- entry.eventDate)
    }
    func getSelectById(id: UUID) -> Table {
        return self.getSelectStatement().filter(self.eventId == id)
    }
    func getSelectStatement() -> Table {
        return self.table.select(self.eventId, self.eventDate, self.caloriesBurned, self.durationInMinutes)
    }
    func getSelectByParentId(parentId: UUID) -> Table? {
        return nil
    }
    func mapRowToEvent(row: Row) throws -> Event {
        let id = try row.get(self.eventId)
        let eventD = try row.get(self.eventDate)
        let calories = try row.get(self.caloriesBurned)
        let minutes = try row.get(self.durationInMinutes)
        return Event(eventId: id, eventDate: eventD, caloriesBurned: calories, durationInMinutes: minutes, activities: nil)
    }
}
