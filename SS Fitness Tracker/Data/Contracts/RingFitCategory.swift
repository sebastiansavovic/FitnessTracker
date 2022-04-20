// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let ringFitCategory = try? newJSONDecoder().decode(RingFitCategory.self, from: jsonData)

import Foundation

// MARK: - RingFitCategory
public class RingFitCategory: Codable {
    public let categoryId:UUID
    public let name: String
    public let canFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case categoryId = "CategoryId"
        case name = "Name"
        case canFavorite = "CanFavorite"
    }

    public init(categoryId: UUID, name: String, canFavorite: Bool) {
        self.categoryId = categoryId
        self.name = name
        self.canFavorite = canFavorite
    }
}

