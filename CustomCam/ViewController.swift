//
//  ViewController.swift
//  CustomCam
//
//  Created by Giri on 18/10/21.
//

import UIKit
import Photos


class ViewController: UIViewController {
    @IBOutlet weak var cameraButton: GCameraButton!
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var cameraSelection: GHPicker!
    private var cameraManager: GCamera?
    override func viewDidLoad() {
        super.viewDidLoad()
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(zoomingGesture(gesture:)))
        self.view.addGestureRecognizer(gesture)
    }
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        super.viewDidAppear(animated)
        self.cameraManager = GCamera(view: self.view)
        self.cameraManager?.camereType = .photo
        self.cameraManager?.videoCompletion = { (fileURL) in
            self.saveInPhotoLibrary(with: fileURL)
            print("finished writing to \(fileURL.absoluteString)")
        }
        self.cameraManager?.photoCompletion = { [weak self] (image) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { saved, error in
                if saved {
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "Your image was successfully saved", message: nil, preferredStyle: .alert)
                        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(defaultAction)
                        self?.present(alertController, animated: true, completion: nil)
                    }
                } else {
                    print(error.debugDescription)
                }
            }
        }
    }
    @objc private func zoomingGesture(gesture: UIPanGestureRecognizer) {
        let velocity = gesture.velocity(in: self.view)
        if velocity.y > 0 {
            self.cameraManager?.zoomOut()
        } else {
            self.cameraManager?.zoomIn()
        }
    }
    //MARK: -  button actions
    @IBAction private func flipButtonPressed(_ button: UIButton) {
        guard let cameraManager = self.cameraManager else { return }
        UIView.transition(with: button , duration: 0.3, options: .transitionFlipFromLeft, animations: {
        cameraManager.flip()
        }, completion: nil)
    }
    @IBAction private func flashButtonPressed(_ button: UIButton) {
        self.cameraManager?.flashMode =  self.cameraManager?.flashMode.next() ?? .off
        switch self.cameraManager?.flashMode {
        case .off:
            UIView.transition(with: button , duration: 0.3, options: .transitionFlipFromTop, animations: {
                button.setImage(UIImage.init(named: "flashOff"), for: .normal)
            }, completion: nil)
        case .auto:
            UIView.transition(with: button , duration: 0.3, options: .transitionFlipFromTop, animations: {
                button.setImage(UIImage.init(named: "flashAuto"), for: .normal)
            }, completion: nil)
        case .on:
            UIView.transition(with: button , duration: 0.3, options: .transitionFlipFromTop, animations: {
                button.setImage(UIImage.init(named: "flashOn"), for: .normal)
            }, completion: nil)
        default:
            UIView.transition(with: button , duration: 0.3, options: .transitionFlipFromTop, animations: {
                button.setImage(UIImage.init(named: "flashOff"), for: .normal)
            }, completion: nil)
        }
    }
    private func saveInPhotoLibrary(with fileURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }) { saved, error in
            if saved {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                print(error.debugDescription)
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
extension CaseIterable where Self: Equatable {
    func next() -> Self {
        let all = Self.allCases
        let idx = all.firstIndex(of: self)!
        let next = all.index(after: idx)
        return all[next == all.endIndex ? all.startIndex : next]
    }
}
//extension ViewController : UIPickerViewDelegate, UIPickerViewDataSource {
//    func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        return 1
//    }
//    
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return 5
//    }
//    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
//        let modeView = UIView()
//        modeView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
//        let modeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
//        modeLabel.textColor = .yellow
//        modeLabel.text = "title"//captureModesList[row]
//        modeLabel.textAlignment = .center
//        modeView.addSubview(modeLabel)
//        modeView.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
//        return modeView
//    }
//    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
//      return 100
//    }
//
//}
extension ViewController : gcamButtonDelegate {
    func imageCapture() {
        debugPrint(#function)
        guard let cameraManager = self.cameraManager else { return }
        cameraManager.camereType = .photo
        DispatchQueue.main.async {
            cameraManager.startRecording()
        }
    }
    
    func videoCapture(isRecording: Bool) {
        print(#function)
        guard let cameraManager = self.cameraManager else { return }
        cameraManager.camereType = .video
        if cameraManager.cameraPosition == .front {
            cameraManager.flashMode = .off
        }
        DispatchQueue.main.async {
            if cameraManager.isRecording {
                cameraManager.stopRecording()
            } else {
                cameraManager.startRecording()
            }
        }
        self.controlView.isHidden =  isRecording
    }
}

