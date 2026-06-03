//
//  QRScannerView.swift
//  podAppFPv1.00
//
//  Created by S R on 3/27/26.
//

import SwiftUI
import AVFoundation
import UIKit

struct QRScannerView: UIViewControllerRepresentable {
    
    @Binding var cameraPosition: AVCaptureDevice.Position
    var onCodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.cameraPosition = cameraPosition
        controller.onCodeScanned = onCodeScanned
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        if uiViewController.cameraPosition != cameraPosition {
            uiViewController.updateCameraPosition(to: cameraPosition)
        }
    }
    
    static func dismantleUIViewController(_ uiViewController: ScannerViewController, coordinator: ()) {
        uiViewController.stopSession()
    }
}
