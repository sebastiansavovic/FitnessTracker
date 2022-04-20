//
//  SelectedImageDetailViewController.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/3/21.
//

import Foundation
import UIKit

class SelectedImageDetailViewController: UIViewController {
    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    var sampleData:SampleActivity? = nil
    var imageWasSelected:((SampleActivity) -> Void)? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let sampleData = sampleData{
            self.image1.image = UIImage(named: sampleData.headerFileName)
            self.image2.image = UIImage(named: sampleData.dataFileName)
        }
    }
    @IBAction func backPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectedPressed(_ sender: Any) {
        if let sampleImage = sampleData {
            if let action = imageWasSelected{
                dismiss(animated: true, completion:{
                    action(sampleImage)
                })
                return
            }
        }
        MyLog.debug("Could not dismiss as selected action was not set")
    }
}
