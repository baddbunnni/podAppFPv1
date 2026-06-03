//
//  DeviceLinkService.swift
//  podAppFPv1.00
//
//  Created by S R on 3/27/26.
//

import Foundation
import OSLog

struct DeviceLinkResponse: Codable {
    let success: String
    let message: String
}

private struct DeviceLinkPayload: Codable {
    let linkid: String
    let deviceid: String
}

enum DeviceLinkService {
    
    static func linkDevice(apiURL: String, linkID: String, deviceID: String) async throws -> DeviceLinkResponse {
        Logger.device.info("Building payload for device link API")
        
        guard let url = URL(string: apiURL) else {
            Logger.device.error("Invalid API URL")
            throw URLError(.badURL)
        }
        
        let payload = DeviceLinkPayload(linkid: linkID, deviceid: deviceID)
        let jsonData = try JSONEncoder().encode(payload)
        
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            Logger.device.error("Could not convert device link JSON to string")
            throw URLError(.cannotDecodeRawData)
        }
        
        Logger.device.info("Device link JSON before base64: \(jsonString, privacy: .public)")
        
        let base64Payload = jsonData.base64EncodedString()
        Logger.device.info("Device link base64 payload length: \(base64Payload.count)")
        
        guard let encodedPayload = base64Payload.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            Logger.device.error("Could not percent-encode device link payload")
            throw URLError(.cannotDecodeRawData)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "json=\(encodedPayload)"
        request.httpBody = bodyString.data(using: .utf8)
        
        Logger.device.info("Device link request URL: \(url.absoluteString, privacy: .public)")
        Logger.device.info("Device link request body length: \(bodyString.count)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.device.error("Invalid HTTP response from device link API")
            throw URLError(.badServerResponse)
        }
        
        Logger.device.info("Device link HTTP status code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            Logger.device.error("Device link failed with HTTP status: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        guard let responseString = String(data: data, encoding: .utf8) else {
            Logger.device.error("Could not convert API response to string")
            throw URLError(.cannotDecodeRawData)
        }
        
        let trimmedResponse = responseString.trimmingCharacters(in: .whitespacesAndNewlines)
        Logger.device.info("Device link raw API response: \(trimmedResponse, privacy: .public)")
        
        guard let decodedData = Data(base64Encoded: trimmedResponse) else {
            Logger.device.error("Could not base64 decode API response")
            throw URLError(.cannotDecodeContentData)
        }
        
        guard let decodedJSONString = String(data: decodedData, encoding: .utf8) else {
            Logger.device.error("Could not convert decoded response data to JSON string")
            throw URLError(.cannotDecodeContentData)
        }
        
        Logger.device.info("Device link decoded JSON string: \(decodedJSONString, privacy: .public)")
        
        let decodedResponse = try JSONDecoder().decode(DeviceLinkResponse.self, from: decodedData)
        Logger.device.info("Device link decoded response: success=\(decodedResponse.success, privacy: .public), message=\(decodedResponse.message, privacy: .public)")
        
        return decodedResponse
    }
}
