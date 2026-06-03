//
//  ContentView.swift
//  podAppFPv1.00
//
//  Created by S R on 3/6/26.
//

import SwiftUI
import AVFoundation
import UIKit
import OSLog

struct ContentView: View {
    
    enum Tab {
        case pod
        case configuration
    }
    
    // MARK: - UI State
    @State private var selectedTab: Tab = .pod
    @State private var showScanner = false
    @State private var cameraPosition: AVCaptureDevice.Position = .back
    @State private var showConfigScanner = false
    @State private var configScannedCode = ""
    @State private var isLinkingDevice = false
    
    // MARK: - Active POD Session
    @State private var selectedScanType: ScanType? = nil
    @State private var scannedItems: [ScanItem] = []
    @State private var vehicleRegistration = ""
    @State private var selectedCourier = ""
    @State private var scannedAWB = ""
    @State private var retrySignatureBase64: String? = nil
    
    // MARK: - Failed Queue / Retry State
    @State private var failedQueue: [PendingUpload] = []
    @State private var retryingUploadIDs: Set<UUID> = []
    @State private var retryStatusByID: [UUID: String] = [:]
    @State private var isAutoRetryingQueue = false
    
    
    // MARK: - Location Manager / Geo Tracking
    @StateObject private var locationManager = LocationManager.shared
    
    // MARK: - Netwrok Monitor
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    // MARK: - Persistent App Storage
    @AppStorage("deviceLinkAPI") private var deviceLinkAPI = ""
    @AppStorage("podUploadAPI") private var podUploadAPI = ""
    @AppStorage("deviceUUID") private var deviceUUID = ""
    @AppStorage("isDeviceLinked") private var isDeviceLinked = false
    @AppStorage("linkedQRCode") private var linkedQRCode = ""
    @AppStorage("deviceLinkMessage") private var deviceLinkMessage = "Not Linked"
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundLayer
            mainContent
            
            if showScanner, let activeScanType = selectedScanType {
                scannerOverlay(for: activeScanType)
            }
        }
        .onAppear {
            handleOnAppear()
        }
        .onChange(of: selectedScanType) { _, newValue in
            persistScanSession(selectedScanType: newValue, scannedItems: scannedItems)
        }
        .onChange(of: scannedItems) { _, newValue in
            persistScanSession(selectedScanType: selectedScanType, scannedItems: newValue)
        }
        .onChange(of: vehicleRegistration) { _, _ in
            persistCurrentSession()
        }
        .onChange(of: selectedCourier) { _, _ in
            persistCurrentSession()
        }
        .onChange(of: scannedAWB) { _, _ in
            persistCurrentSession()
        }
        .onChange(of: retrySignatureBase64) { _, _ in
            persistCurrentSession()
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if isConnected {
                startSequentialAutoRetry()
            }
        }
    }
    
    // MARK: - View Sections
    
    private var backgroundLayer: some View {
        FPTheme.background
            .ignoresSafeArea()
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            networkBanner
            Divider()
            tabContent
            Spacer()
        }
    }
    
    private var headerSection: some View {
        HeaderView(
            selectedTab: selectedTab,
            deviceUUID: deviceUUID,
            isDeviceLinked: isDeviceLinked,
            onSelectPod: {
                selectedTab = .pod
            },
            onSelectConfig: {
                selectedTab = .configuration
            }
        )
    }
    
    private var networkBanner: some View {
        Group {
            if !networkMonitor.isConnected {
                HStack(spacing: 10) {
                    Image(systemName: "wifi.slash")
                    Text("Offline mode — uploads will be queued and retried automatically.")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundColor(.black)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(Color.yellow.opacity(0.35))
            }
        }
    }
    
    @ViewBuilder
    private var tabContent: some View {
        if selectedTab == .pod {
            
            if isDeviceLinked {
                podTabContent
            } else {
                deviceNotLinkedView
            }
            
        } else {
            configurationTabContent
        }
    }
    
    private var deviceNotLinkedView: some View {
        VStack(spacing: 20) {
            
            Image(systemName: "ipad.landscape.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            Text("Device Not Linked")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("This device must be linked before POD scanning can begin.")
                .font(.title3)
                .foregroundColor(FPTheme.graphite)
            
            Button("Go to Configuration") {
                selectedTab = .configuration
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(FPTheme.buttonBackground)
            .foregroundColor(FPTheme.buttonText)
            .shadow(
                color: FPTheme.softShadow,
                radius: 6,
                x: 0,
                y: 3
            )
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var podTabContent: some View {
        PodMenuView(
            selectedScanType: $selectedScanType,
            scannedItems: $scannedItems,
            showScanner: $showScanner,
            cameraPosition: $cameraPosition,
            failedQueue: $failedQueue,
            vehicleRegistration: $vehicleRegistration,
            selectedCourier: $selectedCourier,
            scannedAWB: $scannedAWB,
            retryingUploadIDs: $retryingUploadIDs,
            retryStatusByID: $retryStatusByID,
            onResumeFailedUpload: { pendingUpload in
                restorePendingUploadIntoSession(pendingUpload)
            },
            onRetryFailedUpload: { pendingUpload in
                retryFailedUploadDirect(pendingUpload)
            },
            onDeleteFailedUpload: { pendingUpload in
                PendingUploadStore.remove(id: pendingUpload.id)
                reloadFailedQueue()
            },
            onStartFreshSession: {
                retrySignatureBase64 = nil
            }
        )
    }
    
    private var configurationTabContent: some View {
        ConfigurationView(
            deviceLinkMessage: $deviceLinkMessage,
            configScannedCode: $configScannedCode,
            showConfigScanner: $showConfigScanner,
            isLinkingDevice: $isLinkingDevice,
            deviceLinkAPI: $deviceLinkAPI,
            podUploadAPI: $podUploadAPI,
            isDeviceLinked: isDeviceLinked,
            onScanCode: { code in
                Logger.device.info("QR scanned in configuration area")
                Logger.device.info("Raw scanned code: \(code, privacy: .public)")
                linkDevice(using: code)
            },
            onReconnect: {
                Logger.device.info("Reconnect button tapped")
                showConfigScanner = true
            },
            onDisconnect: {
                Logger.device.info("Disconnect button tapped")
                disconnectDevice()
            }
        )
    }
    
    private func scannerOverlay(for activeScanType: ScanType) -> some View {
        ScannerOverlay(
            vehicleRegistration: vehicleRegistration,
            selectedCourier: selectedCourier,
            scannedAWB: scannedAWB,
            selectedScanType: activeScanType,
            scannedItems: $scannedItems,
            showScanner: $showScanner,
            cameraPosition: $cameraPosition,
            retrySignatureBase64: $retrySignatureBase64,
            onPendingQueueChanged: {
                reloadFailedQueue()
            },
            onUploadSuccess: {
                clearActiveSession()
            }
        )
    }
    
    // MARK: - Lifecycle
    
    private func handleOnAppear() {
        ensureDeviceUUIDExists()
        restoreScanSession()
        reloadFailedQueue()
    }
    
    private func ensureDeviceUUIDExists() {
        if deviceUUID.isEmpty {
            let newUUID = UUID().uuidString
            deviceUUID = newUUID
            Logger.device.info("Generated new device UUID: \(newUUID, privacy: .public)")
        } else {
            Logger.device.info("Existing device UUID found: \(deviceUUID, privacy: .public)")
        }
    }
    
    // MARK: - Session Persistence
    
    private func restoreScanSession() {
        guard let restored = ScanSessionStore.load() else { return }
        
        selectedScanType = restored.selectedScanType
        scannedItems = restored.scannedItems
        vehicleRegistration = restored.vehicleRegistration
        selectedCourier = restored.selectedCourier
        scannedAWB = restored.scannedAWB
        retrySignatureBase64 = restored.retrySignatureBase64
        
        if !restored.scannedItems.isEmpty {
            Logger.scan.info("Restored active scan session into ContentView")
        }
    }
    
    private func persistScanSession(selectedScanType: ScanType?, scannedItems: [ScanItem]) {
        let session = ActiveScanSession(
            selectedScanType: selectedScanType,
            scannedItems: scannedItems,
            vehicleRegistration: vehicleRegistration,
            selectedCourier: selectedCourier,
            scannedAWB: scannedAWB,
            retrySignatureBase64: retrySignatureBase64
        )
        
        ScanSessionStore.save(session)
    }
    
    private func persistCurrentSession() {
        persistScanSession(
            selectedScanType: selectedScanType,
            scannedItems: scannedItems
        )
    }
    
    private func clearActiveSession() {
        selectedScanType = nil
        vehicleRegistration = ""
        selectedCourier = ""
        scannedAWB = ""
        retrySignatureBase64 = nil
    }
    
    private func restorePendingUploadIntoSession(_ pendingUpload: PendingUpload) {
        selectedScanType = pendingUpload.selectedScanType
        scannedItems = pendingUpload.scannedItems
        vehicleRegistration = pendingUpload.vehicleRegistration
        selectedCourier = pendingUpload.selectedCourier
        scannedAWB = pendingUpload.scannedAWB
        retrySignatureBase64 = pendingUpload.signatureBase64
        cameraPosition = .back
        showScanner = true
    }
    
    // MARK: - Failed Queue
    
    private func reloadFailedQueue() {
        failedQueue = PendingUploadStore.loadAll().sorted { $0.createdAt > $1.createdAt }
    }
    
    private func retryFailedUploadDirect(_ pendingUpload: PendingUpload) {
        Task {
            await retryFailedUploadDirectSequential(pendingUpload)
        }
    }
    
    private func clearRetryStatusLater(for id: UUID) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            retryStatusByID[id] = nil
        }
    }
    
    private func startSequentialAutoRetry() {
        guard networkMonitor.isConnected else { return }
        guard !failedQueue.isEmpty else { return }
        guard !isAutoRetryingQueue else { return }
        
        isAutoRetryingQueue = true
        
        Task {
            let queueSnapshot = failedQueue
            
            for item in queueSnapshot {
                if !networkMonitor.isConnected {
                    break
                }
                
                await retryFailedUploadDirectSequential(item)
            }
            
            await MainActor.run {
                isAutoRetryingQueue = false
            }
        }
    }
    
    private func retryFailedUploadDirectSequential(_ pendingUpload: PendingUpload) async {
        await MainActor.run {
            retryingUploadIDs.insert(pendingUpload.id)
            retryStatusByID[pendingUpload.id] = "Retrying..."
        }
        
        do {
            let requestBody = try ScanSessionManager.makeUploadRequest(
                selectedScanType: pendingUpload.selectedScanType,
                scannedItems: pendingUpload.scannedItems,
                deviceUUID: deviceUUID,
                signatureBase64: pendingUpload.signatureBase64,
                vehicleRegistration: pendingUpload.vehicleRegistration,
                selectedCourier: pendingUpload.selectedCourier,
                scannedAWB: pendingUpload.scannedAWB,
                latitude: locationManager.latitude,
                longitude: locationManager.longitude
            )
            
            let response = try await PODUploadService.uploadPOD(
                apiURL: podUploadAPI,
                requestBody: requestBody
            )
            
            let normalized = response.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            await MainActor.run {
                retryingUploadIDs.remove(pendingUpload.id)
                
                if normalized == "success" {
                    PendingUploadStore.remove(id: pendingUpload.id)
                    retryStatusByID[pendingUpload.id] = "Success"
                    reloadFailedQueue()
                    clearRetryStatusLater(for: pendingUpload.id)
                } else {
                    retryStatusByID[pendingUpload.id] = "Failed again"
                    Logger.upload.error("Retry failed again: \(response, privacy: .public)")
                    clearRetryStatusLater(for: pendingUpload.id)
                }
            }
        } catch {
            await MainActor.run {
                retryingUploadIDs.remove(pendingUpload.id)
                retryStatusByID[pendingUpload.id] = "Failed again"
                Logger.upload.error("Retry error: \(error.localizedDescription, privacy: .public)")
                clearRetryStatusLater(for: pendingUpload.id)
            }
        }
    }
    
    // MARK: - Device Linking
    
    private func linkDevice(using qrCode: String) {
        Logger.device.info("Starting device link process")
        
        guard !deviceLinkAPI.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Logger.device.error("Device Link API is empty")
            deviceLinkMessage = "Device Link API Missing"
            return
        }
        
        guard !deviceUUID.isEmpty else {
            Logger.device.error("Device UUID is missing")
            deviceLinkMessage = "Device UUID Missing"
            return
        }
        
        isLinkingDevice = true
        deviceLinkMessage = "Linking..."
        
        Logger.device.info("Device Link API URL: \(deviceLinkAPI, privacy: .public)")
        Logger.device.info("linkid: \(qrCode, privacy: .public)")
        Logger.device.info("deviceid: \(deviceUUID, privacy: .public)")
        
        Task {
            do {
                let response = try await DeviceLinkService.linkDevice(
                    apiURL: deviceLinkAPI,
                    linkID: qrCode,
                    deviceID: deviceUUID
                )
                
                await MainActor.run {
                    Logger.device.info("API response received")
                    Logger.device.info("success: \(response.success, privacy: .public)")
                    Logger.device.info("message: \(response.message, privacy: .public)")
                    
                    if response.success == "1" {
                        isDeviceLinked = true
                        linkedQRCode = qrCode
                        deviceLinkMessage = response.message
                        Logger.device.info("Device linked state saved locally")
                    } else {
                        isDeviceLinked = false
                        deviceLinkMessage = response.message
                        Logger.device.error("Device link failed according to API")
                    }
                    
                    isLinkingDevice = false
                }
            } catch {
                await MainActor.run {
                    Logger.device.error("Device link request failed: \(error.localizedDescription, privacy: .public)")
                    isDeviceLinked = false
                    deviceLinkMessage = "Link Failed"
                    isLinkingDevice = false
                }
            }
        }
    }
    
    private func disconnectDevice() {
        Logger.device.info("Clearing local device link state")
        isDeviceLinked = false
        linkedQRCode = ""
        configScannedCode = ""
        deviceLinkMessage = "Not Linked"
        Logger.device.info("Device disconnected locally")
    }
}

#Preview {
    ContentView()
}
