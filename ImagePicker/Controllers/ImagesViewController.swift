//
//  ViewController.swift
//  ImagePicker
//
//  Created by Alex Paul on 1/20/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import AVFoundation // we want to use AVMakeRec() to maintain image aspect ratio

// Future features:
/*

- Share
- Automatically save original image taken to the photo library
 */

class ImagesViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var imageObjects = [ImageObject]()
    
    private var ImagePickerController = UIImagePickerController()
    
    private let dataPersistance = PersistenceHelper(filename: "images.plist")
    
    private var selectedImage: UIImage? {
        didSet {
            appendNewPhotoToCollection()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        // set imagePickerController delegete as this view controller
        ImagePickerController.delegate = self
        loadImageObjects()
    }
    private func loadImageObjects() {
        do {
            imageObjects = try dataPersistance.loadEvents()
        } catch {
            print("error")
        }
    }
    
    private func appendNewPhotoToCollection() {
        guard let image = selectedImage else {
            print("image is nil")
            return
        }
        
        print("original image size is \(image.size)")
        
        // the size for resizing of the image
        let size = UIScreen.main.bounds.size
        // we will maintain the aspect ratio of the image
        let rec = AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin: CGPoint.zero, size: size))
        
        // resize image
        let resizeImage = image.resizeImage(to: rec.size.width, height: rec.size.height)
        
        print("new image size is \(resizeImage.size)")
        guard let resizedImageData = resizeImage.jpegData(compressionQuality: 1.0) else {
            return
        }
        
        
        // create an image object using the image selected
        let imageObject = ImageObject(imageData: resizedImageData, date: Date())
        
        // insert new imageObject into imageObjects
        imageObjects.insert(imageObject, at: 0)
        
        // create an indexPath for insertion into collection view
        
        let indexPath = IndexPath(row: 0, section: 0)
        
        // insert new cell into collection view
        collectionView.insertItems(at: [indexPath])
        
        // Persist imageObject to documents directory
        do {
            try dataPersistance.create(item: imageObject)
        } catch {
            print("saving error")
        }
    }
    
    @IBAction func addPictureButtonPressed(_ sender: UIBarButtonItem) {
        // We want to present an action sheet to the user.
        // The action sheet will be: camera, photo library, cancel
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] alertAction in
            self?.showImageController(isCameraSelected: true)
            
        }
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self]
            alertAction in
            self?.showImageController(isCameraSelected: false)
            
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        // Check if camera is available
        // if camera is not available, the app will crash
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(cameraAction)
        }
        alertController.addAction(photoLibraryAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    private func showImageController(isCameraSelected: Bool) {
        // source type default will be .photosLibrary
        ImagePickerController.sourceType = .photoLibrary
        
        if isCameraSelected {
            ImagePickerController.sourceType = .camera
        }
        present(ImagePickerController, animated: true)
    }
    
}

// MARK: - UICollectionViewDataSource
extension ImagesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageObjects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // step 4: creating custom delegation - must have an instance of object B
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? ImageCell else {
            fatalError("could not downcast to an ImageCell")
        }
        let images = imageObjects[indexPath.row]
        cell.configuredCell(imageObject: images)
        // step 5: creating custom delegation -> set delegate object
        // similar to tableView.delegete = self
        cell.delegate = self
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ImagesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maxWidth: CGFloat = UIScreen.main.bounds.size.width
        let itemWidth: CGFloat = maxWidth * 0.80
        return CGSize(width: itemWidth, height: itemWidth)  }
}

extension  ImagesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // we need to access the UIImagePickerController.InfoKey.orginalImage key tp get the UImage that was selected.
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            print("Image selected not found")
            return
        }
        selectedImage = image
        
        dismiss(animated: true)
    }
}

extension ImagesViewController: ImageCellDelegate {
    func didLongPress(_ imageCell: ImageCell) {
        print("cell was selected")
        guard let indexPath = collectionView.indexPath(for: imageCell) else {
            return
        }
        // present an action sheet
        
        // actions: delete, cancel
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] alertAction in
            self?.deleteImageObject(indexPath: indexPath)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    private func deleteImageObject(indexPath: IndexPath) {
        do {
            try dataPersistance.delete(event: indexPath.row)
            
            imageObjects.remove(at: indexPath.row)
            
            collectionView.deleteItems(at: [indexPath])
        } catch {
            print("error")
        }
    }
    
    
}

// more here: https://nshipster.com/image-resizing/
// MARK: - UIImage extension
extension UIImage {
    func resizeImage(to width: CGFloat, height: CGFloat) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}


