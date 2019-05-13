//
//  ViewController.swift
//  CatML
//
//  Created by MikeyT on 3/23/19.
//  Copyright © 2019 MikeyT. All rights reserved.
//

import UIKit
import AVKit
import CoreML
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var cameraDisplay: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCamera()
        
        
    }
    
    func setUpCamera(){
        guard let device = AVCaptureDevice.default(for: .video) else {return}
        guard let input = try? AVCaptureDeviceInput(device: device) else {return}
        let session = AVCaptureSession()
        //bloew sets session quality to 4k
        session.sessionPreset = .hd4K3840x2160
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        cameraDisplay.layer.addSublayer(previewLayer)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "CameraOutput"))
        
        session.addInput(input)
        session.addOutput(output)
        session.startRunning()
    }
    //from AVCapture delegate in class signature
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let sampleBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        scanImage(buffer: sampleBuffer)
    }
    
    func scanImage(buffer: CVPixelBuffer){
        //get ml model
        guard let model = try? VNCoreMLModel(for: catML().model) else {return}
        let request = VNCoreMLRequest(model: model) { request, _ in
            guard let results = request.results as? [VNClassificationObservation] else {return}
            guard let mostConfidentResult = results.first else {return}
            
            DispatchQueue.main.async {
                if mostConfidentResult.confidence >= 0.95 {
                    let confidenceText = "\n \(Int(mostConfidentResult.confidence * 100.0))% confidence"
                
                    switch mostConfidentResult.identifier {
                        
//                    case "appleWatch":self.resultLabel.text = "APPLE WATCH \(confidenceText)"
                    case "snickers":self.resultLabel.text = "CAT\(confidenceText)"
                        default: return
                    }
                }else{
                    self.resultLabel.text = "Unknown object, need more data"
                }
                
            }
       
            
           
        }
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])
        do{
            try requestHandler.perform([request])
        }catch{
            print(error)
        }
        
    
    }


}

