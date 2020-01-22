//
//  ImageCell.swift
//  ImagePicker
//
//  Created by Alex Paul on 1/20/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit


// Step 1: Creating custom  delegation
protocol ImageCellDelegate: AnyObject { // AnyObject requares ImageCellDelegate only works with class types
    
    // list required functions, initializers, variables
    func didLongPress(_ imageCell: ImageCell)
}


class ImageCell: UICollectionViewCell {
    
    // step 2: creating custom delegation - define optional delegete variable
    
    weak var delegate: ImageCellDelegate?

  @IBOutlet weak var imageView: UIImageView!
  
    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer()
        gesture.addTarget(self, action :#selector(longPressAction(gesture:)) )
        return gesture
    }()
    
  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = 20.0
    backgroundColor = .orange
    addGestureRecognizer(longPressGesture)
  }
    public func configuredCell(imageObject: ImageObject) {
        guard let image = UIImage(data: imageObject.imageData) else {
            return
        }
        imageView.image = image
    }
    
    @objc
    private func longPressAction(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            gesture.state = .cancelled
            return
            
        }
//        print("long pressed")
        // step 3: creating custom delegation - explicity use delegete object to notify of any update e.g notifying the imageViewController 
        delegate?.didLongPress(self)
    }
}
