//
//  ConfigurationView.swift
//  podAppFPv1.00
//
//  Created by S R on 3/6/26.
//

import SwiftUI
import AVFoundation
import OSLog

struct ConfigurationView: View {
    
    enum ConfigField {
        case deviceLink
        case podUpload
    }
    
    @Binding var deviceLinkMessage: String
    @Binding var configScannedCode: String
    @Binding var showConfigScanner: Bool
    @Binding var isLinkingDevice: Bool
    @Binding var deviceLinkAPI: String
    @Binding var podUploadAPI: String
    
    let isDeviceLinked: Bool
    let onScanCode: (String) -> Void
    let onReconnect: () -> Void
    let onDisconnect: () -> Void
    
    @FocusState private var focusedField: ConfigField?
    @Environment(\.openURL) private var openURL
    
    private let trainingPDFURL = "https://www.fpgroup.co.uk/FPGAPI/FPG_WMS_Training.pdf"
    private let usagePDFURL = "https://www.fpgroup.co.uk/FPGAPI/FPG_Terms_Conditions.pdf"
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 24) {
                
                networkAccessCard
                    .frame(width: geometry.size.width * 0.32, height: 420, alignment: .topLeading)
                
                deviceLinkStatusCard
                    .frame(width: geometry.size.width * 0.58, height: geometry.size.height - 48, alignment: .topLeading)
                
                Spacer(minLength: 0)
            }
            .padding(24)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
            }
        }
    }
    
    private var networkAccessCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CONFIGURATION")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Network Access Setting")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Device Link API")
                    .font(.headline)
                
                TextField("Enter device link API / URL", text: $deviceLinkAPI)
                    .font(.caption)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .deviceLink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("POD Upload API")
                    .font(.headline)

                TextField("Enter podupload.php API / URL", text: $podUploadAPI)
                    .font(.caption)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .podUpload)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            HStack(spacing: 12) {
                Button("Training") {
                    openTrainingPDF()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(FPTheme.buttonBackground)
                .foregroundColor(FPTheme.buttonText)
                .shadow(
                    color: FPTheme.softShadow,
                    radius: 6,
                    x: 0,
                    y: 3
                )
                .cornerRadius(10)

                Button("Usage") {
                    openUsagePDF()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(FPTheme.secondaryButtonBackground)
                .foregroundColor(.black)
                .cornerRadius(10)
            }

            Spacer()

            Image("FP Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 320, height: 320)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)
                   
            
        }
        .padding(24)
        .background(FPTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: FPTheme.softShadow, radius: 10, x: 0, y: 4)
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private var deviceLinkStatusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Device Link Status")
                .font(.title)
                .fontWeight(.bold)
            
            Text(deviceLinkMessage)
                .font(.title3)
                .foregroundColor(isDeviceLinked ? .green : .red)
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(FPTheme.subtleBorder, lineWidth: 1)
                    .background(Color.clear)
                
                if showConfigScanner {
                    QRScannerView(cameraPosition: .constant(.back)) { code in
                        guard !isLinkingDevice else { return }
                        configScannedCode = code
                        showConfigScanner = false
                        onScanCode(code)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    VStack(spacing: 8) {
                        Text("QR Scanner Area")
                            .font(.title3)
                            .foregroundColor(FPTheme.graphite)
                        
                        Text("Tap to open camera")
                            .font(.subheadline)
                            .foregroundColor(FPTheme.graphite)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                showConfigScanner.toggle()
            }
            
            Text(showConfigScanner ? "Tap the scanner area again to hide the camera." : "Tap the scanner area to open the camera and scan a QR code.")
                .foregroundColor(FPTheme.graphite)
            
            if !configScannedCode.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Last scanned QR:")
                        .font(.headline)
                    
                    Text(configScannedCode)
                        .font(.subheadline)
                        .foregroundColor(FPTheme.graphite)
                        .textSelection(.enabled)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Scan / Reconnect", action: onReconnect)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(FPTheme.buttonBackground)
                    .foregroundColor(FPTheme.buttonText)
                    .shadow(
                        color: FPTheme.softShadow,
                        radius: 6,
                        x: 0,
                        y: 3
                    )
                    .cornerRadius(10)
                
                Button("Disconnect", action: onDisconnect)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(FPTheme.secondaryButtonBackground)
                    .foregroundColor(.black)
                    .cornerRadius(10)
            }
        }
        .padding(24)
        .background(FPTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: FPTheme.softShadow, radius: 10, x: 0, y: 4)
    }
    
    private func openTrainingPDF() {
        guard let url = URL(string: trainingPDFURL), !trainingPDFURL.isEmpty else {
            Logger.device.error("Training PDF URL is missing or invalid")
            return
        }
        openURL(url)
    }
    
    private func openUsagePDF() {
        guard let url = URL(string: usagePDFURL), !usagePDFURL.isEmpty else {
            Logger.device.error("Usage PDF URL is missing or invalid")
            return
        }
        openURL(url)
    }
}
