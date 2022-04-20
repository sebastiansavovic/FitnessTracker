//
//  Extensions.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 2/26/21.
// Some sources include components from:
//
//
//

import Foundation
import UIKit
import SQLite


///
/// from https://github.com/ivlevAstef/DITranquillity but taken appart, so likely applying differently than original
/// eliminated the code that I did not need, eliminated the need to be a package as all I needed are these 2 classes, eliminated the inject to particular view, as it seemed it defeated the purpose
@propertyWrapper
public struct Dependency<Target, Value> {
    public init(_ type: Target.Type) {}
    
    public var wrappedValue: Value {
        Resolver.resolve(Target.self)!
    }
}

public struct Resolver {
    public typealias Factory<Value> = () -> Value
    
    private static var factories: [ObjectIdentifier: [ObjectIdentifier: Factory<Any>]] = [:]
    public static func resolve<Target, Value>(
        _ target: Target.Type = Target.self,
        value: Value.Type = Value.self) -> Value? {
        factories[.init(target)]?[.init(value)]?() as? Value
    }
    
    public static func register<Target>(
        _ target: Target.Type = Target.self,
        value: @autoclosure @escaping Factory<Target>) {
        let targetKey = ObjectIdentifier(target)
        register(targetKey: targetKey, value: value)
    }
    
    private static func register(
        targetKey: ObjectIdentifier,
        value: @escaping Factory<Any>) {
        if factories[targetKey] == nil {
            factories[targetKey] = [targetKey: value]
        } else {
            factories[targetKey]![targetKey] = value
        }
    }
    
    public static func clear() {
        factories = [:]
    }
}

extension UIStackView {
    func removeAllArrangedSubviews() {
        let removedSubviews = arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            self.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        for v in removedSubviews {
            if v.superview != nil {
                NSLayoutConstraint.deactivate(v.constraints)
                v.removeFromSuperview()
            }
        }
    }
}

class MyLog {
    static func debug(_ message: String, file: String = #file, line: Int = #line, function: String = #function)  {
        NSLog("\(file):\(line) : \(function) (\(message))")
    }
}

extension UUID: Value {
    public static var declaredDatatype = String.declaredDatatype
    
    public static func fromDatatypeValue(_ datatypeValue: String) -> UUID {
        //        if let id = UUID(uuidString: datatypeValue) {
        //            return id
        //        }
        return UUID(uuidString: datatypeValue)!
    }
    
    
    public var datatypeValue: String {
        self.uuidString
    }
}

/// From a stck overflow question
extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()
}



extension UIView {
    
    /// Returns a collection of constraints to anchor the bounds of the current view to the given view.
    ///  https://www.avanderlee.com/swift/auto-layout-programmatically/
    /// - Parameter view: The view to anchor to.
    /// - Returns: The layout constraints needed for this constraint.
    func constraintsForAnchoringTo(boundsOf view: UIView) -> [NSLayoutConstraint] {
        return [
            topAnchor.constraint(equalTo: view.topAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ]
    }
}

extension UIColor {
    class var lightBlue: UIColor {
        return UIColor(named: "LightBlue")!
    }
    class var caloriesLine: UIColor {
        return UIColor(named: "CaloriesLine")!
    }
    class var minutesActive: UIColor {
        return UIColor(named: "MinutesActive")!
    }
    class var numberOfActivities: UIColor {
        return UIColor(named: "NumberOfActivities")!
    }
}

extension Double {
    func toDateFrom2020() -> Date {
        let timeSince1970 = Int(self)
        let timeInterval = TimeInterval(timeSince1970 + MyConstants.Days2020From29170)
        return Date(timeIntervalSince1970: timeInterval)
    }
}
struct MyConstants {
    static var _2020:Date = {
        var dateComponents = DateComponents()
        dateComponents.year = 2020
        dateComponents.month = 1
        dateComponents.day = 1
        return Calendar.current.date(from: dateComponents)!
    }()
    static var Days2020From29170:Int = {
        return Int(MyConstants._2020.timeIntervalSince1970)
    }()
}
extension Date {
    
    func getDaysSince2021() -> Int {
        return Int(self.timeIntervalSince(MyConstants._2020))
    }
    static  let months = ["", // so I can use month as index
                          "Jan", "Feb", "Mar",
                          "Apr", "May", "Jun",
                          "Jul", "Aug", "Sep",
                          "Oct", "Nov", "Dec"]
    func getDayOfMonth() -> Int {
        return Calendar.current.component(.day, from: self)
    }
    func getMonth() -> Int {
        
        return Calendar.current.component(.month, from: self)
    }
    func getYear() -> Int {
        
        return Calendar.current.component(.year, from: self)
    }
    func toShortDateString() -> String {
        let month = self.getMonth()
        let day = self.getDayOfMonth()
        let year = self.getYear()
        return "\(Date.months[month]) \(day) \(year)"
    }
    func toStringMonthDay() -> String {
        let month = self.getMonth()
        let day = self.getDayOfMonth()
        return "\(Date.months[month])-\(day)"
    }
    func getDayOfWeek() -> DayOfWeek {
        let dayofWeek = Calendar.current.component(.weekday, from: self)
        if let result = DayOfWeek(rawValue: Int64(dayofWeek)) {
            return result
        }
        return .None
    }
}

public extension UIImage {
    func copy(newSize: CGSize, retina: Bool = true) -> UIImage? {
        // In next line, pass 0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
        // Pass 1 to force exact pixel size.
        UIGraphicsBeginImageContextWithOptions(
            /* size: */ newSize,
            /* opaque: */ false,
            /* scale: */ retina ? 0 : 1
        )
        defer { UIGraphicsEndImageContext() }
        
        self.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
// from stack overflow
extension StringProtocol {
    func stringPriorTo<S: StringProtocol>(of string: S) -> String? {
        if let index = self.index(of: string, options: .caseInsensitive) {
            let substring = self[..<index]
            return String(substring)
        }
        return nil
    }
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
              let range = self[startIndex...]
                .range(of: string, options: options) {
            result.append(range)
            startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}

