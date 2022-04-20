//
//  ImageSelectorViewController.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/3/21.
//

import Foundation
import UIKit


class ImageSelectorViewController : UIViewController,  UITableViewDelegate, UITableViewDataSource {
    @Dependency(AssetRepository.self)var assetRepository:AssetRepository
    
    @IBOutlet weak var sampleImages: UITableView!

    var imageSelected:((SampleActivity) -> Void)? = nil
    var items:SampleActivities = SampleActivities()
    let cellReuseIdentifier = "imageCell"
    var selectedCell:SampleImagesCell? = nil
    let segueId = "viewDetailSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sampleImages.dataSource = self
        self.sampleImages.delegate = self
        self.items = self.assetRepository.getSampleImages()
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sourceData = self.selectedCell {
            let detailController = segue.destination as! SelectedImageDetailViewController
            detailController.sampleData = sourceData.sampleImage
            detailController.imageWasSelected = imageWasSelected
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (self.sampleImages.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! SampleImagesCell?)!
        
        let sampleImage = self.items[indexPath.row]
        cell.sampleImage = sampleImage
        cell.picture1!.image = UIImage(named: sampleImage.headerFileNameThumbNail)!
        cell.picture2!.image = UIImage(named: sampleImage.dataFileNameThumbNail)!
        cell.textLabel?.text = sampleImage.eventDate
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedCell = tableView.cellForRow(at: indexPath) as? SampleImagesCell
        self.performSegue(withIdentifier: self.segueId, sender: self)
    }
    func imageWasSelected(image: SampleActivity){
        if let action = imageSelected {
            dismiss(animated: true, completion: {
                action(image)
            })
        }
    }
    
}

