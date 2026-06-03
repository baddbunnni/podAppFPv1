//
//  PendingUpload.swift
//  podAppFPv1.00
//
//  Created by S R on 4/10/26.
//

import Foundation

struct PendingUpload: Identifiable, Codable, Equatable {
    let id: UUID
    let selectedScanType: ScanType
    let scannedItems: [ScanItem]
    let signatureBase64: String
    let createdAt: Date
    let vehicleRegistration: String
    let selectedCourier: String
    let scannedAWB: String

    init(
        id: UUID = UUID(),
        selectedScanType: ScanType,
        scannedItems: [ScanItem],
        signatureBase64: String,
        createdAt: Date = Date(),
        vehicleRegistration: String = "",
        selectedCourier: String = "",
        scannedAWB: String = ""
    ) {
        self.id = id
        self.selectedScanType = selectedScanType
        self.scannedItems = scannedItems
        self.signatureBase64 = signatureBase64
        self.createdAt = createdAt
        self.vehicleRegistration = vehicleRegistration
        self.selectedCourier = selectedCourier
        self.scannedAWB = scannedAWB
    }
}
