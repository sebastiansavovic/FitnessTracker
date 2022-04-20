//
//  ImageAnalyzer.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/4/21.
//

import Foundation
import UIKit
import Vision

class ImageAnalyzer {
    @Dependency(AssetRepository.self)var assetRepository:AssetRepository
    private var openRequests:[UUID: CompletionHelper]
    private let caloriesString = "Total Calories Burned"
    private let minutesString = "Total Time Exercising"
    private let totalDistanceString = "Total Distance Run"
    private let nextString = "Next"
    init() {
        openRequests = [UUID: CompletionHelper]()
    }
    private var summaryTask:CustomTextRequest? = nil
    private var detailTask:CustomTextRequest? = nil
    
    private func initializeRecongizer(dataType: DataType, id: UUID) -> CustomTextRequest {
        if dataType == .Detail{
            if let task = detailTask{
                task._id = id
                return task
            }
        }
        if dataType == .Summary{
            if let task = summaryTask{
                task._id = id
                return task
            }
        }
        let textRecognitionRequest = CustomTextRequest(completionHandler: handler, dataType: dataType, id: id)
        
        var words:[String] = []
        if dataType == .Detail {
            let ringData = self.assetRepository.getRingFitActivities()
            for activity in ringData {
                words.append(activity.name)
            }
        }
        else if dataType == .Summary {
            words.append(caloriesString)
            words.append(minutesString)
            words.append(totalDistanceString)
            words.append(nextString)
        }
        textRecognitionRequest.customWords = words
        textRecognitionRequest.recognitionLanguages = ["en-US"]
        textRecognitionRequest.usesLanguageCorrection = true
        textRecognitionRequest.recognitionLevel = .accurate
        
        if dataType == .Detail {
            detailTask = textRecognitionRequest
        }
        if dataType == .Summary {
            summaryTask = textRecognitionRequest
        }
        return textRecognitionRequest
    }
    private func matchId(ids:[String], id: String) -> String? {
        for s in ids {
            if s.contains(id) {
                return s
            }
        }
        return nil
    }
    private func processSummaryData(data:[String]) -> Event {
        let ids = [caloriesString, minutesString, totalDistanceString, nextString]
        var mappings = [String: String]()
        
        var currentId:String? = nil
        for s in data {
            if let id = matchId(ids: ids, id: s) {
                currentId = id
            }
            else if let currentId = currentId {
                let oldValue = mappings[currentId] ?? ""
                mappings[currentId] = "\(oldValue)\(s)"
            }
        }
        var calories = 0
        var duration = 0
        if let mapping = mappings[caloriesString] {
            calories = parseInt(mapping)
        }
        
        if let mapping = mappings[minutesString] {
            duration = parseTime(mapping)
        }
        return Event(eventId: UUID(), eventDate: Date(), caloriesBurned: calories, durationInMinutes: duration, activities: nil)
    }
    private func parseTime(_ value: String) -> Int {
        var totalmin = 0
        var temp = value
        if let hr = temp.stringPriorTo(of: "hr") {
            totalmin = parseInt(hr) * 60
            temp = temp.replacingOccurrences(of: hr, with: "")
        }
        if let min = temp.stringPriorTo(of: "min") {
            totalmin = parseInt(min)
        }
        return totalmin
    }
    fileprivate func parseInt(_ target: String) -> Int{
        let regex = try! NSRegularExpression(pattern: "[0-9]+", options: .caseInsensitive)
        let range = NSRange(location: 0, length: target.utf16.count)
        if let candidate = regex.firstMatch(in: target, options: [], range: range)
        {
            let resultValue = String(target[Range(candidate.range, in: target)!])
            
            return Int(resultValue)!
        }
        return 0
    }
    
    private func processDetailData(data:[String]) -> [Activity] {
        var currentId:UUID? = nil
        var mappings = [UUID: String]()
        for s in data {
            if let id = self.assetRepository.getActivityIdByName(name: s) {
                currentId = id
                mappings[id] = ""
            }
            else if let currentId = currentId {
                let oldValue = mappings[currentId] ?? ""
                mappings[currentId] = "\(oldValue)\(s)"
            }
        }
        var activities = [Activity]()
        for kvp in mappings {
            let activity = self.assetRepository.getRingActivityById(id: kvp.key)
            let target = kvp.value
            let value = parseInt(target)
            activities.append(Activity(activityId: UUID(), eventId: UUID(), categoryId: activity.categoryId, activitySource: activity.activitySource, value: value, cumulativeValue: 0, modifier: "reps", originalValue: kvp.value, name: activity.name))
        }
        return activities
    }
    private func processData(id: UUID, dataType: DataType, data:[String]){
        guard let completionItem = self.openRequests[id] else {
            MyLog.debug("\(id) is not present in open requests")
            return
        }
        if dataType == .Detail {
            completionItem.parsedActivities = self.processDetailData(data: data)
            completionItem.detailData = data
            completionItem.detailReceived = true
        }
        else if dataType == .Summary {
            completionItem.ParsedEvent = self.processSummaryData(data: data)
            completionItem.summaryData = data
            completionItem.summaryReceived = true
        }
        if completionItem.isDone {
            if let event = completionItem.ParsedEvent{
                let localActivities = completionItem.parsedActivities.map({
                    $0.cloneShallowWithNewParentId(id: event.eventId)
                })
                event.activities = localActivities
                completionItem.completionEvent(event)
            }
            else {
                completionItem.completionEvent(Event(eventId: id, eventDate: Date(), caloriesBurned: 0, durationInMinutes: 0, activities: completionItem.parsedActivities))
            }
            self.openRequests.removeValue(forKey: id)
        }
    }
    private func handler(request: VNRequest, error: Optional<Error>) {
        let orgRequest = request as! CustomTextRequest
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        let recognizedStrings = observations.compactMap { observation in
            return observation.topCandidates(1).first?.string
        }
        processData(id: orgRequest._id, dataType: orgRequest._dataType, data: recognizedStrings)
    }
    fileprivate func processImage(_ image: UIImage, _ handler: CustomTextRequest) {
        if let imageRef = image.cgImage {
            let requestHandler = VNImageRequestHandler(cgImage: imageRef, options: [:])
            DispatchQueue.main.async {
                do {
                    try requestHandler.perform([handler])
                } catch {
                    MyLog.debug("was not able to be loaded due to: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func analyzeSummaryData(images: SampleActivity, processResults:@escaping (Event) -> Void) {
        let id = UUID()
        
        let completionHelper = CompletionHelper(event: processResults)
        self.openRequests[id] = completionHelper
        
        let headerHandler = self.initializeRecongizer(dataType: .Summary, id: id)
        let imageSummary = UIImage(named: images.headerFileName)!
        processImage(imageSummary, headerHandler)
        
        let detailHandler = self.initializeRecongizer(dataType: .Detail, id: id)
        let imageDetails = UIImage(named: images.dataFileName)!
        processImage(imageDetails, detailHandler)
    }
}
fileprivate class CompletionHelper {
    let completionEvent:((Event) -> Void)
    var summaryData:[String]
    var detailData:[String]
    var parsedActivities:[Activity]
    var ParsedEvent:Event?
    var detailReceived:Bool
    var summaryReceived:Bool
    var isDone: Bool {
        get {
            return self.detailReceived && self.summaryReceived
        }
    }
    init(event:@escaping ((Event) -> Void)) {
        completionEvent = event
        summaryData = []
        detailData = []
        parsedActivities = []
        detailReceived = false
        summaryReceived = false
        ParsedEvent = nil
    }
}
