//
//  ActivityDtoCell.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/7/21.
//

import Foundation
import UIKit

typealias ActivityValueChanged = (ActivityWithDateDto, Int) -> (Void)

class ActivityDtoCell : UITableViewCell {
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var activityTitle: UILabel!
    
    var previouValue:Int = 0
    var valueChanged:ActivityValueChanged? = nil
    private var _activity:ActivityWithDateDto?
    var activity:ActivityWithDateDto {
        get{
            return _activity!
        }
        set(newValue) {
            _activity = newValue
            self.activityTitle.text = newValue.activityName
            self.previouValue = newValue.value
            self.valueTextField.text = String(self.previouValue)
        }
    }
    
    @IBAction func editingChanged(_ sender: UITextField) {
        let newValue = sender.text ?? ""
        var valueDidChange = false
        if newValue == "" {
            previouValue = 0
        }
        else if let val = Int(newValue) {
            valueDidChange = val != previouValue
            previouValue = val
        }       
        valueTextField.text = String(previouValue)
        if valueDidChange {
            if let valueChanged = valueChanged {
                valueChanged(activity, previouValue)
            }
        }
    }
    deinit {
        valueChanged = nil
    }
}
