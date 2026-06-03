//
//  PODUploadService.swift
//  podAppFPv1.00
//
//  Created by S R on 3/27/26.
//

import Foundation
import OSLog

enum PODUploadService {
    
    static func uploadPOD(
        apiURL: String,
        requestBody: PODUploadRequest
    ) async throws -> String {
        
        Logger.upload.info("Building payload for POD upload API")
        
        guard let url = URL(string: apiURL) else {
            Logger.upload.error("Invalid POD upload API URL")
            throw URLError(.badURL)
        }
        
        let jsonData = try JSONEncoder().encode(requestBody)
        
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            Logger.upload.error("Could not convert JSON data to string")
            throw URLError(.cannotDecodeRawData)
        }
        
        Logger.upload.info("POD upload JSON: \(jsonString, privacy: .public)")
        
        let base64Payload = jsonData.base64EncodedString()
        Logger.upload.info("POD upload base64 payload length: \(base64Payload.count)")
        
        guard let encodedPayload = base64Payload.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            Logger.upload.error("Could not percent-encode POD upload payload")
            throw URLError(.cannotDecodeRawData)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "json=\(encodedPayload)"
        request.httpBody = bodyString.data(using: .utf8)
        
        Logger.upload.info("POD upload request URL: \(url.absoluteString, privacy: .public)")
        Logger.upload.info("POD upload HTTP method: \(request.httpMethod ?? "UNKNOWN", privacy: .public)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.upload.error("Invalid HTTP response from POD upload API")
            throw URLError(.badServerResponse)
        }
        
        Logger.upload.info("POD upload HTTP status code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            Logger.upload.error("POD upload failed with HTTP status: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        guard let responseText = String(data: data, encoding: .utf8) else {
            Logger.upload.error("Could not decode POD upload response")
            throw URLError(.cannotDecodeRawData)
        }

        let trimmedResponse = responseText.trimmingCharacters(in: .whitespacesAndNewlines)

        Logger.upload.info("POD upload raw response: \(trimmedResponse, privacy: .public)")

        print("POD UPLOAD STATUS:", httpResponse.statusCode)
        print("POD UPLOAD RESPONSE BODY:", trimmedResponse)
        print("POD UPLOAD REQUEST JSON:", jsonString)

        return trimmedResponse
    }
}
