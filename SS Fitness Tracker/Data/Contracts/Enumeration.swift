//
//  Enumeration.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/4/21.
//

import Foundation
import SQLite

enum DataType {
    case Summary
    case Detail
}
enum DayOfWeek: Int64, Value, CaseIterable  {
    public static var declaredDatatype = Int64.declaredDatatype
    
    public static func fromDatatypeValue(_ datatypeValue: Int64) -> DayOfWeek {
        if let result = DayOfWeek(rawValue: datatypeValue) {
            return result
        }
        return DayOfWeek.None
    }
    public var datatypeValue: Int64 {
        self.rawValue
    }
    case None = 0
    case Sunday = 1
    case Monday = 2
    case Tuesday = 3
    case Wednesday = 4
    case Thrusday = 5
    case Friday = 6
    case Saturday = 7
    
    
}


public enum FavoriteType: Int64, Value {
    public static var declaredDatatype = Int64.declaredDatatype
    
    
    public static func fromDatatypeValue(_ datatypeValue: Int64) -> FavoriteType {
        if let result = FavoriteType(rawValue: datatypeValue) {
            return result
        }
        return FavoriteType.None
    }
    
    public var datatypeValue: Int64 {
        self.rawValue
    }
    
    case None = 0
    case Favorite = 1
    case Ignore = 2
}

enum EventTypes {
    case None
    case Deleted
    case Inserted
    case Updated
}
