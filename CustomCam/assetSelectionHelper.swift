//
//  assetSelectionHelper.swift
//  CustomCam
//
//  Created by Giri on 22/10/21.
//

import Foundation
import UIKit
import Photos
import AVFoundation
import PhotosUI
import AVKit
class AssetSelectionViewController: UIViewController {
    var imagePickerController = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func openGallery(isCam:Bool) {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            DispatchQueue.main.async {
                self.showGallery(isCam:isCam)
            }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({
                (newStatus) in
                if newStatus ==  PHAuthorizationStatus.authorized {
                    DispatchQueue.main.async {
                        self.showGallery(isCam:isCam)
                    }
                }
            })
            print("It is not determined until now")
        case .restricted:
            // same same
            print("User do not have access to photo album.")
        case .denied:
            // same same
            print("User has denied the permission.")
        case .limited:
            // same same
            print("User has denied the permission.")
        @unknown default:
            break
        }
    }
    func showGallery(isCam:Bool) {
        if  !isCam , #available(iOS 14, *) {
            var configuration = PHPickerConfiguration()
            //            configuration.filter = .videos
            configuration.selectionLimit = 1
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        } else {
            if UIImagePickerController.isSourceTypeAvailable(isCam ? UIImagePickerController.SourceType.camera : UIImagePickerController.SourceType.photoLibrary){
                imagePickerController = UIImagePickerController ()
                imagePickerController.sourceType = isCam ? .camera : .photoLibrary
                imagePickerController.delegate = self
                imagePickerController.allowsEditing = true
                imagePickerController.mediaTypes = ["public.movie"]
                present(imagePickerController, animated: true, completion: nil)
            } else {
                let alert  = UIAlertController(title: "Warning", message: "You don't have permission to access \(isCam ? "camera":"gallery").", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    func loadAsset(_ asset: AVAsset?,_ image:UIImage?) {
        // override in subclass
    }
}
extension AssetSelectionViewController : UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[UIImagePickerController.InfoKey.mediaURL ] as? URL {
            let asset = AVAsset.init(url: videoURL)
            DispatchQueue.main.async { [self] in
                loadAsset(asset, nil)
            }
        } else {
            let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            loadAsset(nil, image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
@available(iOS 14, *)
extension AssetSelectionViewController : PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard let provider = results.first?.itemProvider else { return }
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: [:]) { [self] (videoURL, error) in
                DispatchQueue.main.async {
                    if let url = videoURL as? URL {
                        let asset = AVAsset.init(url: url)
                        loadAsset(asset, nil)
                    }
                }
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async { [unowned self] in
                        self.loadAsset(nil, image)
                    }
                }
            })
        }
    }
}
