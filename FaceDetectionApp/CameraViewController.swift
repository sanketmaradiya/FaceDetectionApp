//
//  CameraViewController.swift
//  FaceDetectionApp
//
//  Created by Nimap on 06/02/25.
//

import AVFoundation
import UIKit
import Vision

protocol CameraViewControllerDelegate: AnyObject {
    func didCaptureImage(with url: URL)
}

class CameraViewController: UIViewController {
    
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureOutput: AVCapturePhotoOutput?
    var faceDetectionRequest: VNRequest?
    var faceLayer = CAShapeLayer()
    var faceDetected = false
    var captureTimer: Timer?
    var currentCameraPosition: AVCaptureDevice.Position = .back
    
    weak var delegate: CameraViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera(position: .back)
        setupUI()
        setupFaceDetection()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.captureSession?.stopRunning()
        self.faceDetectionRequest?.cancel()
        
    }
    
    func setupCamera(position: AVCaptureDevice.Position) {
        captureSession?.stopRunning()
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            print("No camera found")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureOutput = AVCapturePhotoOutput()
            
            captureSession?.beginConfiguration()
            
            if let captureSession = captureSession {
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                }
                if captureSession.canAddOutput(captureOutput!) {
                    captureSession.addOutput(captureOutput!)
                }
                
                previewLayer?.removeFromSuperlayer()
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.videoGravity = .resizeAspectFill
                previewLayer?.frame = view.layer.bounds
                
                DispatchQueue.main.async {
                    self.view.layer.insertSublayer(self.previewLayer!, at: 0)
                }
                
                captureSession.commitConfiguration()
                
                DispatchQueue.global(qos: .userInitiated).async {
                    captureSession.startRunning()
                }
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
        
        faceLayer.strokeColor = UIColor.red.cgColor
        faceLayer.lineWidth = 3
        faceLayer.fillColor = UIColor.clear.cgColor
        view.layer.addSublayer(faceLayer)
    }

    
    func setupUI() {
        let captureButton = UIButton()
        captureButton.backgroundColor = .red
        captureButton.layer.cornerRadius = 35
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)
        
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
        ])
        
        let frontCameraButton = UIButton()
        frontCameraButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        frontCameraButton.tintColor = .white
        frontCameraButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        frontCameraButton.layer.cornerRadius = 35
        frontCameraButton.translatesAutoresizingMaskIntoConstraints = false
        frontCameraButton.addTarget(self, action: #selector(toggleCamera), for: .touchUpInside)
        view.addSubview(frontCameraButton)
        
        NSLayoutConstraint.activate([
            frontCameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            frontCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            frontCameraButton.widthAnchor.constraint(equalToConstant: 70),
            frontCameraButton.heightAnchor.constraint(equalToConstant: 70),
        ])
    }
    
    func setupFaceDetection() {
        faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { [weak self] request, error in
            guard let results = request.results as? [VNFaceObservation], let strongSelf = self else { return }
            DispatchQueue.main.async {
                strongSelf.handleFaceDetection(results)
            }
        })
    }
    
    func handleFaceDetection(_ results: [VNFaceObservation]) {
        guard let previewLayer = previewLayer else { return }
        
        if results.isEmpty {
            faceLayer.path = nil
            faceDetected = false
            captureTimer?.invalidate()
            return
        }
        
        if !faceDetected {
            faceDetected = true
            captureTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(capturePhoto), userInfo: nil, repeats: false)
        }
        
        let faceBounds = results.first!.boundingBox
        let convertedRect = previewLayer.layerRectConverted(fromMetadataOutputRect: faceBounds)
        
        let path = UIBezierPath(rect: convertedRect)
        faceLayer.path = path.cgPath
    }
    
    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        captureOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    @objc func toggleCamera() {
        currentCameraPosition = (currentCameraPosition == .back) ? .front : .back
        setupCamera(position: currentCameraPosition)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else { return }
            
            let finalImage: UIImage
            if currentCameraPosition == .front {
                finalImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .leftMirrored)
            } else {
                finalImage = image
            }
            
            if let imageURL = saveImageToDocuments(finalImage) {
                delegate?.didCaptureImage(with: imageURL)
            }
            captureSession?.stopRunning()
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
    
    func saveImageToDocuments(_ image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return nil }
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = directory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        DispatchQueue.main.async {
            do {
                try requestHandler.perform([self.faceDetectionRequest!])
            } catch {
                print("Face detection failed: \(error)")
            }
        }
        
    }
}
