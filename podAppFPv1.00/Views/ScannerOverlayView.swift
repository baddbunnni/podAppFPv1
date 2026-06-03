//
//  ScannerOverlayView.swift
//  podAppFPv1.00
//
//  Created by S R on 3/27/26.
//

import SwiftUI
import AVFoundation
import UIKit
import OSLog

struct ScannerOverlay: View {
    
    let vehicleRegistration: String
    let selectedCourier: String
    let scannedAWB: String
    let selectedScanType: ScanType
    @Binding var scannedItems: [ScanItem]
    @Binding var showScanner: Bool
    @Binding var cameraPosition: AVCaptureDevice.Position
    @Binding var retrySignatureBase64: String?
    
    var onPendingQueueChanged: () -> Void
    var onUploadSuccess: () -> Void
    
    @AppStorage("podUploadAPI") private var podUploadAPI = ""
    @AppStorage("deviceUUID") private var deviceUUID = ""
    
    @State private var showSignaturePad = false
    @State private var scanStatusMessage = "Point the camera at a QR code. Back camera opens by default."
    @State private var scanStatusColor = Color.white.opacity(0.9)
    @State private var isUploading = false
    @StateObject private var locationManager = LocationManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                
                HStack(spacing: 20) {
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Scans (\(scannedItems.count))")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if scannedItems.isEmpty {
                            Text("No scans yet")
                                .foregroundColor(FPTheme.graphite)
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(Array(scannedItems.enumerated()), id: \.element.id) { index, item in
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack(alignment: .top) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Scan \(index + 1)")
                                                        .font(.headline)
                                                        .fontWeight(.semibold)
                                                    
                                                    Text(item.code)
                                                        .font(.subheadline)
                                                        .foregroundColor(FPTheme.graphite)
                                                        .textSelection(.enabled)
                                                    
                                                    Text(item.scanType.rawValue)
                                                        .font(.caption)
                                                        .foregroundColor(FPTheme.graphite)
                                                }
                                                
                                                Spacer()
                                                
                                                Button(action: {
                                                    scannedItems.removeAll { $0.id == item.id }
                                                }) {
                                                    Image(systemName: "xmark")
                                                        .font(.caption.bold())
                                                        .foregroundColor(.black)
                                                        .padding(8)
                                                        .background(FPTheme.secondaryButtonBackground)
                                                        .clipShape(Circle())
                                                }
                                                .buttonStyle(.plain)
                                                .disabled(isUploading)
                                            }
                                            
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            guard !isUploading else { return }

                            if let savedSignature = retrySignatureBase64 {
                                uploadCurrentSession(signatureBase64: savedSignature)
                            } else {
                                showSignaturePad = true
                            }
                        }) {
                            Text(isUploading ? "UPLOADING..." : (retrySignatureBase64 == nil ? "CAPTURE SIGNATURE" : "RETRY UPLOAD"))
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(FPTheme.buttonBackground)
                                .foregroundColor(FPTheme.buttonText)
                                .shadow(
                                    color: FPTheme.softShadow,
                                    radius: 6,
                                    x: 0,
                                    y: 3
                                )
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .disabled(scannedItems.isEmpty || isUploading)
                    }
                    .padding(20)
                    .frame(width: geometry.size.width * 0.28)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: FPTheme.softShadow, radius: 10, x: 0, y: 4)
                    
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SCAN POD")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text(selectedScanType.rawValue)
                                    .font(.headline)
                                    .foregroundColor(FPTheme.graphite)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                cameraPosition = cameraPosition == .back ? .front : .back
                            }) {
                                Image(systemName: "camera.rotate")
                                    .font(.title2)
                                    .foregroundColor(.black)
                                    .padding(10)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(isUploading)
                            
                            Button(action: {
                                showScanner = false
                                retrySignatureBase64 = nil
                            }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.black)
                                    .padding(10)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(isUploading)
                        }
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black)
                            
                            QRScannerView(cameraPosition: $cameraPosition) { code in
                                handleScannedCode(code)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Text(scanStatusMessage)
                            .foregroundColor(scanStatusColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(20)
                    .frame(width: geometry.size.width * 0.62, height: geometry.size.height * 0.82)
                    .background(Color.gray.opacity(0.85))
                    .cornerRadius(16)
                    .shadow(color: FPTheme.softShadow, radius: 10, x: 0, y: 4)
                }
                .frame(width: geometry.size.width * 0.94, height: geometry.size.height * 0.86)
                
                if showSignaturePad {
                    SignatureCaptureOverlay(
                        onBack: {
                            showSignaturePad = false
                        },
                        onSave: { base64Signature in
                            uploadCurrentSession(signatureBase64: base64Signature)
                        }
                    )
                }
                
                if isUploading {
                    ZStack {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.4)
                            
                            Text("Uploading POD...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(30)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(16)
                        .shadow(color: FPTheme.softShadow, radius: 10, x: 0, y: 4)
                    }
                }
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        switch ScanSessionManager.validateIncomingCode(code, existingItems: scannedItems) {
        case .invalid:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            scanStatusMessage = "Invalid QR format"
            scanStatusColor = .red
            
        case .duplicate:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            scanStatusMessage = "Duplicate scan ignored"
            scanStatusColor = .yellow
            
        case .valid(let trimmedCode):
            let newItem = ScanSessionManager.makeScanItem(
                from: trimmedCode,
                scanType: selectedScanType
            )
            
            scannedItems.append(newItem)
            scanStatusMessage = "Scan successful"
            scanStatusColor = .green
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    private func uploadCurrentSession(signatureBase64: String) {
        guard !podUploadAPI.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Logger.upload.error("POD Upload API is empty")
            scanStatusMessage = "POD Upload API Missing"
            scanStatusColor = .red
            return
        }
        
        guard !deviceUUID.isEmpty else {
            Logger.upload.error("Device UUID is missing")
            scanStatusMessage = "Device UUID Missing"
            scanStatusColor = .red
            return
        }
        
        isUploading = true
        scanStatusMessage = "Uploading POD..."
        scanStatusColor = .yellow
        
        Logger.upload.info("Starting POD upload")
        Logger.upload.info("POD Upload API URL: \(podUploadAPI, privacy: .public)")
        Logger.upload.info("systemid: \(deviceUUID, privacy: .public)")
        Logger.upload.info("scanned item count: \(scannedItems.count)")
        Logger.upload.info("signature base64 length: \(signatureBase64.count)")
        
        let requestBody: PODUploadRequest
        
        do {
            requestBody = try ScanSessionManager.makeUploadRequest(
                selectedScanType: selectedScanType,
                scannedItems: scannedItems,
                deviceUUID: deviceUUID,
                signatureBase64: signatureBase64,
                vehicleRegistration: vehicleRegistration,
                selectedCourier: selectedCourier,
                scannedAWB: scannedAWB,
                latitude: locationManager.latitude,
                longitude: locationManager.longitude
            )
        } catch {
            scanStatusMessage = error.localizedDescription
            scanStatusColor = .red
            isUploading = false
            return
        }
        
        Task.detached {
            do {
                let response = try await PODUploadService.uploadPOD(
                    apiURL: podUploadAPI,
                    requestBody: requestBody
                )
                
                await MainActor.run {
                    let normalizedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    Logger.upload.info("POD upload response: \(response, privacy: .public)")
                    
                    if normalizedResponse == "success" {
                        scanStatusMessage = "POD uploaded successfully"
                        scanStatusColor = .green
                        scannedItems.removeAll()
                        showSignaturePad = false
                        showScanner = false
                        retrySignatureBase64 = nil
                        onUploadSuccess()
                    } else {
                        let pendingUpload = PendingUpload(
                            selectedScanType: selectedScanType,
                            scannedItems: scannedItems,
                            signatureBase64: signatureBase64,
                            vehicleRegistration: vehicleRegistration,
                            selectedCourier: selectedCourier,
                            scannedAWB: scannedAWB
                        )
                        PendingUploadStore.save(pendingUpload)
                        onPendingQueueChanged()
                        
                        scanStatusMessage = "Upload failed: \(response)"
                        scanStatusColor = .red
                    }
                    
                    isUploading = false
                }
            } catch {
                await MainActor.run {
                    let pendingUpload = PendingUpload(
                        selectedScanType: selectedScanType,
                        scannedItems: scannedItems,
                        signatureBase64: signatureBase64,
                        vehicleRegistration: vehicleRegistration,
                        selectedCourier: selectedCourier,
                        scannedAWB: scannedAWB
                    )
                    PendingUploadStore.save(pendingUpload)
                    onPendingQueueChanged()
                    
                    Logger.upload.error("POD upload failed: \(error.localizedDescription, privacy: .public)")
                    scanStatusMessage = "Upload failed: \(error.localizedDescription)"
                    scanStatusColor = .red
                    isUploading = false
                }
            }
        }
    }
}
