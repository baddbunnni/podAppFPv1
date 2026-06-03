//
//  PODQRParser.swift
//  podAppFPv1.00
//
//  Created by S R on 4/7/26.
//

import Foundation
import OSLog

struct ParsedPODQR {
    let shipmentID: String
    let customerOrderNumber: String
    let rawValue: String
}

enum PODQRParser {
    
    static func parse(_ raw: String) -> ParsedPODQR? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            Logger.scan.error("QR parse failed: empty value")
            return nil
        }
        
        let parts = trimmed.split(separator: "-", maxSplits: 1).map(String.init)
        
        guard parts.count == 2 else {
            Logger.scan.error("QR parse failed: expected one hyphen in \(trimmed, privacy: .public)")
            return nil
        }
        
        let shipmentID = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let customerOrderNumber = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard shipmentID.count == 10, shipmentID.allSatisfy(\.isNumber) else {
            Logger.scan.error("QR parse failed: shipment ID is not 10 digits in \(trimmed, privacy: .public)")
            return nil
        }
        
        guard !customerOrderNumber.isEmpty else {
            Logger.scan.error("QR parse failed: customer order number missing in \(trimmed, privacy: .public)")
            return nil
        }
        
        Logger.scan.info("QR parsed successfully")
        Logger.scan.info("shipmentID: \(shipmentID, privacy: .public)")
        Logger.scan.info("customerOrderNumber: \(customerOrderNumber, privacy: .public)")
        
        return ParsedPODQR(
            shipmentID: shipmentID,
            customerOrderNumber: customerOrderNumber,
            rawValue: trimmed
        )
    }
}
