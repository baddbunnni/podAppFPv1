//
//  ActiveScanSession.swift
//  podAppFPv1.00
//
//  Created by S R on 4/17/26.
//

import Foundation
struct ActiveScanSession: Codable {
    let selectedScanType: ScanType?
    let scannedItems: [ScanItem]
    let vehicleRegistration: String
    let selectedCourier: String
    let scannedAWB: String
    let retrySignatureBase64: String?
}
