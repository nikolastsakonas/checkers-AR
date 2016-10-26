//
//  ViewController.swift
//  Checkers-AR
//
//  Created by Nikolas Chaconas on 10/21/16.
//  Copyright © 2016 Nikolas Chaconas. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UINavigationControllerDelegate {
    var calibrator : OpenCVWrapper = OpenCVWrapper()

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        calibrator.initializeCalibrator()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func calibrateImage(pickedImage: UIImage) {
        print("\ncalibrating image\n")
        var img: UIImage
        img = calibrator.findChessboardCorners(pickedImage)
        
        //display calibrated image
        imageView.contentMode = .scaleAspectFit
        imageView.image = img
    }

    @IBAction func beginCalibrationButtonPressed(_ sender: AnyObject) {
        var session = AVCaptureSession()
        if session.canSetSessionPreset(AVCaptureSessionPresetMedium) {
            session.sessionPreset = AVCaptureSessionPresetMedium
        }

        let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        captureVideoPreviewLayer?.frame = imageView.bounds
        
        imageView.layer.addSublayer(captureVideoPreviewLayer!)
        
        let device = AVCaptureDevice()
        let input : AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: device)
            session.addInput(input)
        } catch _ {
            print ("error")
        }
        
        
        
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.frame = imageView.bounds;
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        imageView.layer.addSublayer(previewLayer!)
        
        session.startRunning()
    }

}

