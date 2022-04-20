// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let ringFitActivity = try? newJSONDecoder().decode(RingFitActivity.self, from: jsonData)

import Foundation
import UIKit

// MARK: - RingFitActivity
public class RingFitActivity: Codable {
    public let activitySource: UUID
    public let categoryId: UUID
    public let name, range: String
    public let isRecovery: Bool
    public let coolDown: Int
    public let power: String
    public let hashTags: [String]?
    public let locationFound: String

    enum CodingKeys: String, CodingKey {
        case categoryId = "CategoryId"
        case activitySource = "ActivitySource"
        case name = "Name"
        case range = "Range"
        case isRecovery = "IsRecovery"
        case coolDown = "CoolDown"
        case power = "Power"
        case hashTags = "HashTags"
        case locationFound = "LocationFound"
    }

    public init(categoryId: UUID, activitySource: UUID, name: String, range: String, isRecovery: Bool, coolDown: Int, power: String, hashTags: [String]?, locationFound: String) {
        self.categoryId = categoryId
        self.activitySource = activitySource
        self.name = name
        self.range = range
        self.isRecovery = isRecovery
        self.coolDown = coolDown
        self.power = power
        self.hashTags = hashTags
        self.locationFound = locationFound
    }
    public func getIcon() -> UIImage? {
        let namedImage = "\(self.activitySource.uuidString.lowercased()).png"
        if let icon = UIImage(named: namedImage) {
            return icon
        }
        if let icon = UIImage(named: "main.jpg"){
            return icon
        }
        return nil
    }
    public func toHtml(category: String, sum: Int) -> String {
        var hashtagString = ""
        if let items = hashTags {
            hashtagString = items.joined(separator: "<br>")
        }
        let newRange = range.replacingOccurrences(of: "⚫", with: "&#9899").replacingOccurrences(of: "●", with: "&#9679")
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
                          <h3>
                       \(category)
                            </h3>
                            <div style='margin-left: 30px;''>
                            <table>
                              <tr>
                               <td> Total: </td><td> \(sum)</td>
                              </tr>
                              <tr>
                                 <td> Range: </td><td> \(newRange)</td>
                              </tr>
                              <tr>
                                <td>CoolDown:</td><td> \(coolDown)</td>
                              </tr>
                              <tr>
                                <td>Power:</td> <td>\(power)</td>
                              </tr>
                              <tr>
                               <td> Hash Tags:</td><td> \(hashtagString)</td>
                              </tr>
                              <tr>
                                <td> Location Found:</td><td> \(locationFound)</td>
                               </tr>
                            </table>
                          </div>
                      </div>
                  </body>
                </html>

            """
    }
}

