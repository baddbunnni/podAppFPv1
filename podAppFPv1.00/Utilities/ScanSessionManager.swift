//
//  ScanSessionManager.swift
//  podAppFPv1.00
//
//  Created by S R on 4/10/26.
//

import Foundation
import OSLog

enum ScanValidationResult {
    case valid(String)
    case duplicate
    case invalid
}

enum ScanSessionBuildError: LocalizedError {
    case noScannedItems
    case noValidBarcodes
    
    var errorDescription: String? {
        switch self {
        case .noScannedItems:
            return "No scanned items"
        case .noValidBarcodes:
            return "No valid barcodes to upload"
        }
    }
}

enum ScanSessionManager {
    
    static func validateIncomingCode(
        _ rawCode: String,
        existingItems: [ScanItem]
    ) -> ScanValidationResult {
        let trimmedCode = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard PODQRParser.parse(trimmedCode) != nil else {
            Logger.scan.error("Invalid QR format scanned")
            return .invalid
        }
        
        if existingItems.contains(where: { $0.code == trimmedCode }) {
            Logger.scan.info("Duplicate QR ignored: \(trimmedCode, privacy: .public)")
            return .duplicate
        }
        
        Logger.scan.info("Valid QR accepted: \(trimmedCode, privacy: .public)")
        return .valid(trimmedCode)
    }
    
    static func makeScanItem(
        from code: String,
        scanType: ScanType
    ) -> ScanItem {
        ScanItem(
            code: code,
            scanType: scanType,
            timestamp: Date()
        )
    }
    
    static func makeUploadRequest(
        selectedScanType: ScanType,
        scannedItems: [ScanItem],
        deviceUUID: String,
        signatureBase64: String,
        vehicleRegistration: String,
        selectedCourier: String,
        scannedAWB: String,
        latitude: String,
        longitude: String
    ) throws -> PODUploadRequest {
        
        guard !scannedItems.isEmpty else {
            Logger.upload.error("No scanned items available for upload")
            throw ScanSessionBuildError.noScannedItems
        }
        
        let latitudeValue = cleanCoordinate(latitude)
        let longitudeValue = cleanCoordinate(longitude)
        let signatureNameValue = "N/A"
        
        let dataFields: [PODUploadDataField] = [
            PODUploadDataField(
                status: selectedScanType.rawValue,
                latitude: nil,
                longitude: nil,
                signaturename: nil,
                signatureimage: nil
            ),
            PODUploadDataField(
                status: nil,
                latitude: latitudeValue,
                longitude: longitudeValue,
                signaturename: nil,
                signatureimage: nil
            ),
            PODUploadDataField(
                status: nil,
                latitude: nil,
                longitude: nil,
                signaturename: signatureNameValue,
                signatureimage: nil
            ),
            PODUploadDataField(
                status: nil,
                latitude: nil,
                longitude: nil,
                signaturename: nil,
                signatureimage: signatureBase64
            )
        ]
        
        let timestampFormatter = DateFormatter()
        timestampFormatter.dateFormat = "dd/MM/yyyy, HH:mm:ss"
        timestampFormatter.locale = Locale(identifier: "en_GB")

        let barcodeItems: [PODUploadBarcode] = scannedItems.compactMap { item in
            guard let parsed = PODQRParser.parse(item.code) else {
                Logger.upload.error("Skipping invalid QR during upload: \(item.code, privacy: .public)")
                return nil
            }

            return PODUploadBarcode(
                uniqueid: "\(parsed.shipmentID)-\(selectedScanType.rawValue)",
                timestamp: timestampFormatter.string(from: item.timestamp),
                barcode: parsed.shipmentID,
                orderid: parsed.customerOrderNumber
            )
        }
        
        guard !barcodeItems.isEmpty else {
            Logger.upload.error("No valid barcodes available for upload")
            throw ScanSessionBuildError.noValidBarcodes
        }
        
        Logger.upload.info("Upload request built successfully")
        Logger.upload.info("Barcode count: \(barcodeItems.count)")
        
        return PODUploadRequest(
            data: dataFields,
            barcodes: barcodeItems,
            systemid: deviceUUID
        )
    }
    
    private static func cleanCoordinate(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty || trimmed == "0" || trimmed == "0.0" {
            return "NO GPS SIGNAL"
        }
        
        return trimmed
    }
}
