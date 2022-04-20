//
//  ActivityCell.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/10/21.
//

import Foundation
import UIKit

typealias ActivityDataChanged = (Activity) -> (Void)
typealias Completion = () -> Void
typealias ShowModal = (UIAlertController, @escaping Completion ) -> Void

class ActivityCell : UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var valueChanged:ActivityDataChanged? = nil
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        activities.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.activities[row].name
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedTemp = row
    }
    private var selectedTemp:Int  = -1
    
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var activityTitle: UIButton!
    var action: ShowModal? = nil
    var activities:[RingFitActivity] = [RingFitActivity]()
    private var _activity: Activity? = nil
    private var previouValue: Int = 0
    var activity: Activity {
        get{
            return _activity!
        }
        set(newValue) {
            _activity = newValue
            //            self.activityTitle.setTitle(newValue.name, for: .application)
            self.textLabel?.text = newValue.name
            self.previouValue = newValue.value
            self.valueTextField.text = String(self.previouValue)
            self.selectedTemp = self.getIndexOf(id: newValue.activitySource) ?? 0
        }
    }
    
    
    private func getIndexOf(id: UUID) -> Int? {
        if let row = self.activities.firstIndex(where: {
            $0.activitySource == id
        }){
            return row
        }
        return nil
    }
    
    
    @IBAction func textChanged(_ sender: UITextField) {
        var valueDidChange = false
        let newValue = sender.text ?? ""
        if newValue == "" {
            previouValue = 0
        }
        else if let val = Int(newValue) {
            valueDidChange = val != previouValue
            previouValue = val
        }
        valueTextField.text = String(previouValue)
        if valueDidChange {
            let newActivity = activity.cloneWithNewValue(newValue: previouValue)
            self.activity = newActivity
            if let valueChanged = valueChanged {
                valueChanged(newActivity)
            }
        }
    }
    @IBAction func showPicker(_ sender: Any) {
        if let activity = self._activity {
            let title = "pick activity"
            let message = "\n\n\n\n\n\n\n\n\n\n"
            let alert =  UIAlertController(title: title, message: message, preferredStyle: .alert)
            let w = self.frame.width * 0.6
            let pickerFrame: CGRect = CGRect(x: 15, y: 52, width: w, height: 190)
            let picker: UIPickerView = UIPickerView(frame: pickerFrame)
            picker.dataSource = self
            picker.delegate = self
            
            alert.view.addSubview(picker)
            if let index = self.getIndexOf(id: activity.activitySource) {
                //picker.reloadAllComponents()
                picker.selectRow(index, inComponent: 0, animated: true)
            }
            
            let select = UIAlertAction(title: "select", style: .default, handler: {
                (action) ->  Void in
                let newSource = self.activities[self.selectedTemp].activitySource
                let newActivity = activity.cloneWithNewValue(newSource: newSource)
                self.activity = newActivity
                if let valueChanged = self.valueChanged {
                    valueChanged(newActivity)
                }
            })
            let cancel = UIAlertAction(title: "cancel", style: .cancel, handler: {
                (action) ->  Void in
                MyLog.debug("Cancelled")
            })
            alert.addAction(cancel)
            
            alert.addAction(select)
            
            if let action = self.action {
                action(alert, {
                    
                })
            }
            
            
        }
    }
    
}
