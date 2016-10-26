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
    let ud = UserDefaults.standard
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var beginGameButton: UIButton!
    @IBOutlet weak var beginCalibrationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        if let data = ud.object(forKey: "calibrator") as? NSData {
            calibrator = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! OpenCVWrapper
            
            //debugging
            calibrator.setBloop(3000)
            ud.set(NSKeyedArchiver.archivedData(withRootObject: calibrator), forKey: "calibrator")

            print("getting bloop")
            print(calibrator.getBloop())
            beginCalibrationButton.setTitle("Calibration has been Done", for: .normal)
            beginCalibrationButton.alpha = 0.2;
            beginGameButton.alpha = 1.0;
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func finishCalibration() {
        calibrator.finishCalibration()
        //debugging
        calibrator.setBloop(3000)
        ud.set(NSKeyedArchiver.archivedData(withRootObject: calibrator), forKey: "calibrator")
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
        let session = AVCaptureSession()
        if session.canSetSessionPreset(AVCaptureSessionPresetMedium) {
            session.sessionPreset = AVCaptureSessionPresetMedium
        }

        let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        captureVideoPreviewLayer?.frame = imageView.bounds
        
        imageView.layer.addSublayer(captureVideoPreviewLayer!)
        let backCamera = AVCaptureDevice.defaultDevice(withMediaType:AVMediaTypeVideo)
        do
        {
            let input = try AVCaptureDeviceInput(device: backCamera)
            session.addInput(input)
        }
        catch
        {
            print("can't access camera")
            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.frame = imageView.bounds;
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        imageView.layer.addSublayer(previewLayer!)
        
        session.startRunning()
    }

    @IBAction func beginGameButtonPressed(_ sender: AnyObject) {
        //begin the game
    }
}

