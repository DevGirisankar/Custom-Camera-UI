//
//  GCamera.swift
//  CustomCam
//
//  Created by Giri on 18/10/21.
//

import Foundation
import UIKit
import AVFoundation

class GCamera: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate,
               AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        self.isRecording = false
        if (error != nil) {
            
            print("Error recording movie: \(error!.localizedDescription)")
            
        } else {
            self.videoCompletion?(outputFileURL)
        }
        
    }
    
    typealias VideoCompletion = (URL) -> Void
    typealias PhotoCompletion = (UIImage) -> Void
    
    public enum CameraType {
        case photo
        case video
    }
    
    public enum CameraPosition {
        case front
        case back
    }
    public enum FlashMode: CaseIterable{
        //Return the equivalent AVCaptureDevice.FlashMode
        var AVFlashMode: AVCaptureDevice.FlashMode {
            switch self {
            case .on:
                return .on
            case .off:
                return .off
            case .auto:
                return .auto
            }
        }
        //Flash mode is set to auto
        case auto
        
        //Flash mode is set to on
        case on
        
        //Flash mode is set to off
        case off
    }
    /// Returns true if the torch (flash) is currently enabled
    fileprivate var isCameraTorchOn  = false
    
    private let recordingQueue = DispatchQueue(label: "recording.queue")
    private let view: UIView
    private let photoOutput: AVCapturePhotoOutput = AVCapturePhotoOutput()
    private let session: AVCaptureSession = AVCaptureSession()
    
    private var deviceInput: AVCaptureDeviceInput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private  let movieOutput = AVCaptureMovieFileOutput()
    private var recordingURL: URL?
    private(set) var isRecording: Bool = false
    private var isRecordingSessionStarted: Bool = false
    private(set) var cameraPosition: CameraPosition = .back
    private(set) var zoomFactor: CGFloat = 1.0 {
        didSet {
            if self.zoomFactor < 1.0 || self.zoomFactor > self.maxZoomFactor { return }
            if let device = self.deviceInput?.device {
                do {
                    try device.lockForConfiguration()
                    device.ramp(toVideoZoomFactor: self.zoomFactor, withRate: 3.0)
                    device.unlockForConfiguration()
                }
                catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    open var videoCompletion: VideoCompletion?
    open var photoCompletion: PhotoCompletion?
    open var camereType: CameraType = .photo 
    
    open var maxZoomFactor: CGFloat = 10.0
    public var flashMode:FlashMode  = .off
    
    init(view: UIView) {
        self.view = view
        super.init()
        self.updateFileStorage(with: self.camereType)
        self.initialize()
        self.configureSession()
        self.configurePreview()
    }
    
    open func startRecording() {
        switch self.camereType {
        case .photo:
            guard let camera = AVCaptureDevice.default(for: AVMediaType.video) else { return }
            let settings = getSettings(camera: camera, flashMode: flashMode)
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        case .video:
            self.updateFileStorage(with: self.camereType)
            startvRecording()
        }
    }
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        
        return orientation
    }
    private func startvRecording() {
        recordingQueue.async { [self] in
            if movieOutput.isRecording == false {
                let connection = movieOutput.connection(with: AVMediaType.video)
                if (connection?.isVideoOrientationSupported)! {
                    connection?.videoOrientation = currentVideoOrientation()
                }
                if (connection?.isVideoStabilizationSupported)! {
                    connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
                }
                guard let device = deviceInput?.device else {return}
                if (device.isSmoothAutoFocusSupported) {
                    do {
                        try device.lockForConfiguration()
                        device.isSmoothAutoFocusEnabled = false
                        device.unlockForConfiguration()
                    } catch {
                        print("Error setting configuration: \(error)")
                    }
                }
                if let fileURL = self.recordingURL {
                    movieOutput.startRecording(to: fileURL, recordingDelegate: self)
                    self.isRecording = true
                    if self.cameraPosition == .back && flashMode == .on{
                        enableFlash()
                    }
                }
            } else {
                stopvRecording()
            }
        }
    }
    func stopvRecording() {
        recordingQueue.async { [self] in
            if movieOutput.isRecording == true {
                movieOutput.stopRecording()
            }
            self.isRecordingSessionStarted = false
            self.isRecording = false
            disableFlash()
        }
    }
    
    open func stopRecording() {
        stopvRecording()
    }
    
    open func flip() {
        switch self.cameraPosition {
        case .front:
            self.cameraPosition = .back
            self.addVideoInput(position: .back)
        case .back:
            self.cameraPosition = .front
            self.addVideoInput(position: .front)
        }
        //TODO: we need to configure AVCaptureConnection videoOrientation. It's a temporary solution
        self.configureSession()
    }
    
    open func zoomIn() {
        if self.zoomFactor < self.maxZoomFactor {
            self.zoomFactor = self.zoomFactor + 0.035
        }
    }
    
    open func zoomOut() {
        if self.zoomFactor > 1.0 {
            self.zoomFactor = self.zoomFactor - 0.035
        }
    }
    
    private func updateFileStorage(with mode: CameraType) {
        var fileURL: URL
        fileURL = URL(fileURLWithPath: "\(NSTemporaryDirectory() as String)/video.mov")
        self.recordingURL = fileURL
        print(#function,fileURL)
        let fileManager = FileManager()
        if fileManager.isDeletableFile(atPath: fileURL.path) {
            _ = try? fileManager.removeItem(atPath: fileURL.path)
        }
    }
    
    private func initialize() {
        self.session.sessionPreset = .high
        self.photoOutput.setPreparedPhotoSettingsArray([
            AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])
        ], completionHandler: nil)
        self.cameraPosition = .back
        self.addVideoInput(position: .back)
    }
    
    func addVideoInput(position: AVCaptureDevice.Position) {
        guard let device: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                                    for: .video, position: position) else { return }
        if let currentInput = self.deviceInput {
            self.session.removeInput(currentInput)
            self.deviceInput = nil
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.deviceInput = input
            }
        } catch {
            print(error)
        }
    }
    
    private func configurePreview() {
        let previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        //importent line of code what will did a trick
        previewLayer.videoGravity = .resizeAspectFill
        let rootLayer = self.view.layer
        rootLayer.masksToBounds = true
        previewLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        rootLayer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
        self.session.startRunning()
    }
    
    private func configureSession() {
        DispatchQueue.main.async { [self] in
            
            session.sessionPreset = .high
            // Setup Camera
            let camera = AVCaptureDevice.default(for: AVMediaType.video)!
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if session.canAddInput(input) {
                    session.addInput(input)
                    deviceInput = input
                }
            } catch {
                print("Error setting device video input: \(error)")
            }
            
            // Setup Microphone
            let microphone = AVCaptureDevice.default(for: AVMediaType.audio)!
            
            do {
                let micInput = try AVCaptureDeviceInput(device: microphone)
                if session.canAddInput(micInput) {
                    session.addInput(micInput)
                }
            } catch {
                print("Error setting device audio input: \(error)")
            }
            // Photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            // Movie output
            if session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
            }
        }
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            self.photoCompletion?(image)
        }
    }
}
extension GCamera {
    /// Enable or disable flash for photo
    private func getSettings(camera: AVCaptureDevice, flashMode: FlashMode) -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings()
        
        if camera.hasFlash {
            settings.flashMode = flashMode.AVFlashMode
        }
        return settings
    }
    /// Enable flash
    
    fileprivate func enableFlash() {
        if self.isCameraTorchOn == false {
            toggleFlash()
        }
    }
    
    /// Disable flash
    
    fileprivate func disableFlash() {
        if self.isCameraTorchOn == true {
            toggleFlash()
        }
    }
    
    /// Toggles between enabling and disabling flash
    fileprivate func toggleFlash() {
        guard self.cameraPosition == .back else {
            // Flash is not supported for front facing camera
            return
        }
        
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        // Check if device has a flash
        if (device?.hasTorch)! {
            do {
                try device?.lockForConfiguration()
                if (device?.torchMode == AVCaptureDevice.TorchMode.on) {
                    device?.torchMode = AVCaptureDevice.TorchMode.off
                    self.isCameraTorchOn = false
                } else {
                    do {
                        try device?.setTorchModeOn(level: 1.0)
                        self.isCameraTorchOn = true
                    } catch {
                        print("[GCam]: \(error)")
                    }
                }
                device?.unlockForConfiguration()
            } catch {
                print("[GCam]: \(error)")
            }
        }
    }
    
}
