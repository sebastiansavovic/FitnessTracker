// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let sampleActivities = try? newJSONDecoder().decode(SampleActivities.self, from: jsonData)

import Foundation

// MARK: - SampleActivity
public class SampleActivity: Codable {
    public let eventDate, headerFileNameThumbNail, headerFileName, dataFileNameThumbNail: String
    public let dataFileName: String

    enum CodingKeys: String, CodingKey {
        case eventDate = "EventDate"
        case headerFileNameThumbNail = "HeaderFileNameThumbNail"
        case headerFileName = "HeaderFileName"
        case dataFileNameThumbNail = "DataFileNameThumbNail"
        case dataFileName = "DataFileName"
    }

    public init(eventDate: String, headerFileNameThumbNail: String, headerFileName: String, dataFileNameThumbNail: String, dataFileName: String) {
        self.eventDate = eventDate
        self.headerFileNameThumbNail = headerFileNameThumbNail
        self.headerFileName = headerFileName
        self.dataFileNameThumbNail = dataFileNameThumbNail
        self.dataFileName = dataFileName
    }
}

public typealias SampleActivities = [SampleActivity]
