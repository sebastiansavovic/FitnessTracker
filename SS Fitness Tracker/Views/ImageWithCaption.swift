//
//  ImageWithCaption.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 3/7/21.
//

import Foundation
import UIKit

typealias Selected = (ActivityAggregateDto) -> Void

class ImageWithCaption: UIView {
    let image:UIImageView
    let text:UILabel
    var imageWasSelected:Selected? = nil
    var activity:ActivityAggregateDto? = nil
    override init(frame: CGRect) {
        text = UILabel()
        image = UIImageView()
        super.init(frame: frame)
        
        image.isUserInteractionEnabled = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        image.addGestureRecognizer(tapGestureRecognizer)
    }
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        MyLog.debug("was tapped")
        if let imageWasSelected = imageWasSelected {
            if let activity = activity {
                imageWasSelected(activity)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        text = UILabel()
        image = UIImageView()
        super.init(coder: coder)
        image.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        image.addGestureRecognizer(tapGestureRecognizer)
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        image.translatesAutoresizingMaskIntoConstraints = false
        text.translatesAutoresizingMaskIntoConstraints = false
        let currentWidth = self.frame.size.width
        let currentHeight = self.frame.size.height
        
        self.addSubview(image)
        self.addSubview(text)

        image.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 7).isActive = true
        image.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: currentWidth * 0.15).isActive = true
        
        text.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 3).isActive = true
        
        text.font = text.font.withSize(9)
        text.textAlignment = .center
        let targetText = text.text ?? ""
        let fontAttributes = [NSAttributedString.Key.font: text.font]
        let estimate = (targetText as NSString).size(withAttributes: fontAttributes as [NSAttributedString.Key : Any])
        var textWidth = estimate.width
        var target = (currentWidth - textWidth ) / 2.0//CGFloat(0.0)
        if textWidth > currentWidth {
            textWidth = currentWidth
            target = 0
            
        }
        let targetHeight = currentHeight - image.frame.size.height - 3
        text.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: target).isActive = true

       text.numberOfLines = 3
       text.lineBreakMode = .byWordWrapping

        let tsize = CGSize(width: textWidth, height: targetHeight)
  
        text.sizeThatFits(tsize)
        
        
    }
    deinit {
        imageWasSelected = nil
    }
}
