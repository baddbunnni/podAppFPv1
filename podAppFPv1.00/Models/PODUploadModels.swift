//
//  PODUploadModels.swift
//  podAppFPv1.00
//
//  Created by S R on 3/27/26.
//

import Foundation

struct PODUploadDataField: Codable {
    let status: String?
    let latitude: String?
    let longitude: String?
    let signaturename: String?
    let signatureimage: String?
}

struct PODUploadBarcode: Codable {
    let uniqueid: String
    let timestamp: String
    let barcode: String
    let orderid: String
}

struct PODUploadRequest: Codable {
    let data: [PODUploadDataField]
    let barcodes: [PODUploadBarcode]
    let systemid: String
}
