//
//  ScanType.swift
//  podAppFPv1.00
//
//  Created by S R on 3/27/26.
//

import Foundation

enum ScanType: String, CaseIterable, Identifiable, Codable {
    case dispatchBay = "IN DESPATCH BAY"
    case outForDelivery = "OUT FOR DELIVERY"
    case partialDelivery = "PARTIAL DELIVERY"
    case delivered = "DELIVERED"
    case shippedByCourier = "SHIPPED BY COURIER"
    case returnedUndelivered = "RETURNED UNDELIVERED"
    case returnedIssue = "RETURNED ISSUE"
    case correctiveAction = "CORRECTIVE ACTION"
    case collectedByCourier = "COLLECTED BY COURIER"
    
    var id: String { rawValue }
}
