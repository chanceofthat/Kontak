//
//  KONOnboardProfilePictureViewController.swift
//  Kontak
//
//  Created by Chance Daniel on 3/16/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
import AVFoundation

class KONOnboardProfilePictureViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    var userRef: KONUserReference?
    
    var session: AVCaptureSession?
    var cameraOutput = AVCapturePhotoOutput()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var profilePicture: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraView.makeCircularWithBorderColor(UIColor.konBlue)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set Up Camera
        session = AVCaptureSession()
        if let session = session {
            session.sessionPreset = AVCaptureSessionPresetPhoto
            
            let frontCamera = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front)
            
            var error: NSError?
            var input: AVCaptureDeviceInput?
            
            do {
                input = try AVCaptureDeviceInput(device: frontCamera)
            } catch let _error as NSError {
                error = _error
                print(error!.localizedDescription)
            }
            
            if error == nil && session.canAddInput(input) {
                session.addInput(input)
                
                if (session.canAddOutput(cameraOutput)) {
                    session.addOutput(cameraOutput)
                    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                    if let videoPreviewLayer = videoPreviewLayer {
                        videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                        videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                        cameraView.layer.addSublayer(videoPreviewLayer)
                        session.startRunning()
                    }
                }
            }
            
        }
        if let videoPreviewLayer = videoPreviewLayer {
            videoPreviewLayer.frame = cameraView.bounds
        }
    }
    
    // MARK: - Actions
    
    @IBAction func photoButtonPressed(_ sender: Any) {
        
        if profilePicture == nil {
            photoButton.setTitle("RETAKE PHOTO", for: .normal)

            let settings = AVCapturePhotoSettings()
            let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                                 kCVPixelBufferWidthKey as String: 160,
                                 kCVPixelBufferHeightKey as String: 160]
            settings.previewPhotoFormat = previewFormat
            self.cameraOutput.capturePhoto(with: settings, delegate: self)
        }
        else {
            profilePicture = nil
            for view in cameraView.subviews {
                if view is UIImageView {
                    view.removeFromSuperview()
                }
            }
            photoButton.setTitle("TAKE PHOTO", for: .normal)
        }
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            
            let image = UIImage(data: dataImage)
            if let image = image, let cgImage = image.cgImage {
                profilePicture = UIImage(cgImage: cgImage, scale: image.scale, orientation: UIImageOrientation.leftMirrored)
            
                let imageView = UIImageView(image: profilePicture)
                
                imageView.frame = cameraView.bounds
                imageView.contentMode = .scaleAspectFill
                
                cameraView.addSubview(imageView)
            }
        }
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        

    }
    

}
