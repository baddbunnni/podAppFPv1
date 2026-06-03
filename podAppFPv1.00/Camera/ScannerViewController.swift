//
//  ScannerViewController.swift
//  podAppFPv1.00
//
//  Created by S R on 3/27/26.
//

import UIKit
import AVFoundation

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var onCodeScanned: ((String) -> Void)?
    var cameraPosition: AVCaptureDevice.Position = .back
    
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "fpgroup.camera.session", qos: .userInitiated)
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastScannedCode: String?
    private var lastScanTime: Date = .distantPast
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkPermissionAndConfigure()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updatePreviewOrientation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    func updateCameraPosition(to newPosition: AVCaptureDevice.Position) {
        guard newPosition != cameraPosition else { return }
        cameraPosition = newPosition
        
        sessionQueue.async { [weak self] in
            self?.configureSession(position: newPosition)
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    private func checkPermissionAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            sessionQueue.async { [weak self] in
                guard let self else { return }
                self.configureSession(position: self.cameraPosition)
            }
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                
                if granted {
                    self.sessionQueue.async { [weak self] in
                        guard let self else { return }
                        self.configureSession(position: self.cameraPosition)
                    }
                } else {
                    NSLog("⛔ Camera permission denied by user")
                }
            }
            
        default:
            NSLog("⛔ Camera permission denied or restricted")
        }
    }
    
    private func configureSession(position: AVCaptureDevice.Position) {
        session.beginConfiguration()
        
        for input in session.inputs {
            session.removeInput(input)
        }
        
        for output in session.outputs {
            session.removeOutput(output)
        }
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        
        session.addInput(input)
        
        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else {
            session.commitConfiguration()
            return
        }
        
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
        metadataOutput.metadataObjectTypes = [.qr]
        
        session.commitConfiguration()
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if self.previewLayer == nil {
                let preview = AVCaptureVideoPreviewLayer(session: self.session)
                preview.videoGravity = .resizeAspectFill
                preview.frame = self.view.bounds
                self.view.layer.addSublayer(preview)
                self.previewLayer = preview
            }
            
            self.updatePreviewOrientation()
        }
        
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    private func updatePreviewOrientation() {
        guard let connection = previewLayer?.connection else { return }
        
        let interfaceOrientation = view.window?.windowScene?.interfaceOrientation ?? .landscapeRight
        
        switch interfaceOrientation {
        case .landscapeLeft:
            connection.videoRotationAngle = 180
            
        case .landscapeRight:
            connection.videoRotationAngle = 0
            
        default:
            connection.videoRotationAngle = 0
        }
    }
    
    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil) { _ in
            self.previewLayer?.frame = self.view.bounds
            self.updatePreviewOrientation()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let code = object.stringValue else { return }
        
        let now = Date()
        
        if code == lastScannedCode && now.timeIntervalSince(lastScanTime) < 1.0 {
            return
        }
        
        lastScannedCode = code
        lastScanTime = now
        onCodeScanned?(code)
    }
}
