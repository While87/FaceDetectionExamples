//
//  FaceDetectionService.swift
//  FaceDetect
//
//  Created by Vladimir Gorbunov on 11/24/22.
//

import UIKit
import AVFoundation
import Vision

class FaceDetectionService: NSObject {
    
    private weak var previewView: UIView?
    private weak var faceView: FaceFrameView?
    private var cameraIsReadyToUse = false
    private let session = AVCaptureSession()
    private lazy var cameraPosition = AVCaptureDevice.Position.front
    private weak var previewLayer: AVCaptureVideoPreviewLayer?
    private lazy var sequenceHandler = VNSequenceRequestHandler()
    private lazy var dataOutputQueue = DispatchQueue(label: "FaceDetectionService",
                                                     qos: .userInitiated, attributes: [],
                                                     autoreleaseFrequency: .workItem)
    private var preparingCompletionHandler: ((Bool) -> Void)?
    
    func prepare(previewView: UIView,
                 cameraPosition: AVCaptureDevice.Position,
                 completion: ((Bool) -> Void)?) {
        self.previewView = previewView
        self.preparingCompletionHandler = completion
        self.cameraPosition = cameraPosition
        checkCameraAccess { allowed in
            if allowed { self.setup() }
            completion?(allowed)
            self.preparingCompletionHandler = nil
        }
    }
    
    private func setup() {
        guard let bounds = previewView?.bounds else { return }
        let faceView = FaceFrameView(frame: bounds)
        previewView?.addSubview(faceView)
        faceView.backgroundColor = .clear
        self.faceView = faceView
        configureCaptureSession()
    }
    func start() { if cameraIsReadyToUse { session.startRunning() } }
    func stop() { session.stopRunning() }
}

extension FaceDetectionService {
    private func askUserForCameraPermission(_ completion:  ((Bool) -> Void)?) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { (allowedAccess) -> Void in
            DispatchQueue.main.async { completion?(allowedAccess) }
        }
    }
    
    private func checkCameraAccess(completion: ((Bool) -> Void)?) {
        askUserForCameraPermission { [weak self] allowed in
            guard let self = self, let completion = completion else { return }
            self.cameraIsReadyToUse = allowed
            if allowed {
                completion(true)
            } else {
                self.showDisabledCameraAlert(completion: completion)
            }
        }
    }
    
    private func configureCaptureSession() {
        guard let previewView = previewView else { return }
        // Define the capture device we want to use
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "No front camera available"])
            show(error: error)
            return
        }
        
        // Connect the camera to the capture session input
        do {
            
            try camera.lockForConfiguration()
            defer { camera.unlockForConfiguration() }
            
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
            }
            
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            session.addInput(cameraInput)
            
        } catch {
            show(error: error as NSError)
            return
        }
        
        // Create the video data output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        // Add the video output to the capture session
        session.addOutput(videoOutput)
        
        let videoConnection = videoOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
        
        // Configure the preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewView.bounds
        previewView.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
    }
}

extension FaceDetectionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let detectFaceRequest = VNDetectFaceLandmarksRequest(completionHandler: detectedFace)
        do {
            try sequenceHandler.perform(
                [detectFaceRequest],
                on: imageBuffer,
                orientation: .leftMirrored)
        } catch { show(error: error as NSError) }
    }
}

extension FaceDetectionService {
    private func detectedFace(request: VNRequest, error: Error?) {
        guard   let previewLayer = previewLayer,
                let results = request.results as? [VNFaceObservation],
                let result = results.first
        else {
            faceView?.clearAndSetNeedsDisplay()
            return }
        
        faceView?.read(result: result, previewLayer: previewLayer)
    }
}

// Navigation
extension FaceDetectionService {
    private func show(alert: UIAlertController) {
        DispatchQueue.main.async {
            UIApplication.topViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    private func showDisabledCameraAlert(completion: ((Bool) -> Void)?) {
        let alertVC = UIAlertController(title: "Enable Camera Access",
                                        message: "Please provide access to your camera",
                                        preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: { action in
            guard   let previewView = self.previewView,
                    let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                    UIApplication.shared.canOpenURL(settingsUrl) else { return }
            UIApplication.shared.open(settingsUrl) { [weak self] _ in
                guard let self = self else { return }
                self.prepare(previewView: previewView,
                             cameraPosition: self.cameraPosition,
                             completion: self.preparingCompletionHandler)
            }
        }))
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in completion?(false) }))
        show(alert: alertVC)
    }
    
    private func show(error: NSError) {
        let alertVC = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil ))
        show(alert: alertVC)
    }
}
