//
// ScanItem.swift
//  podAppFPv1.00
//
//  Created by S R on 3/27/26.
//

import Foundation

struct ScanItem: Identifiable, Equatable, Codable {
    let id: UUID
    let code: String
    let scanType: ScanType
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        code: String,
        scanType: ScanType,
        timestamp: Date
    ) {
        self.id = id
        self.code = code
        self.scanType = scanType
        self.timestamp = timestamp
    }
}
