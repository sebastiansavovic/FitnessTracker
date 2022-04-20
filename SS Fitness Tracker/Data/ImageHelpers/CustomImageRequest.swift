//
//  CustomImageRequest.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/4/21.
//

import Foundation
import Vision

class CustomTextRequest : VNRecognizeTextRequest{
    let _dataType:DataType
    var _id:UUID
    public init(completionHandler: VNRequestCompletionHandler? = nil, dataType: DataType, id: UUID){
        _dataType = dataType
        _id = id
        super.init(completionHandler: completionHandler)
    }
}
