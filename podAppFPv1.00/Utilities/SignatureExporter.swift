//
//  SignatureExporter.swift
//  podAppFPv1.00
//
//  Created by S R on 3/27/26.
//

import SwiftUI
import UIKit
import OSLog

enum SignatureExporter {
    
    static func exportBase64PNG(
        lines: [[CGPoint]],
        currentLine: [CGPoint],
        size: CGSize,
        scale: CGFloat = 2.0
    ) -> String? {
        
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = scale
        
        let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)
        
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            UIColor.black.setStroke()
            
            for line in lines {
                guard let firstPoint = line.first else { continue }
                
                let path = UIBezierPath()
                path.move(to: firstPoint)
                
                for point in line.dropFirst() {
                    path.addLine(to: point)
                }
                
                path.lineWidth = 3
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.stroke()
            }
            
            if let firstPoint = currentLine.first {
                let path = UIBezierPath()
                path.move(to: firstPoint)
                
                for point in currentLine.dropFirst() {
                    path.addLine(to: point)
                }
                
                path.lineWidth = 3
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.stroke()
            }
        }
        
        guard let pngData = image.pngData() else {
            Logger.upload.error("Failed to create PNG data from signature")
            return nil
        }
        
        let base64String = pngData.base64EncodedString()
        Logger.upload.info("Signature exported as base64 PNG")
        Logger.upload.info("Signature base64 length: \(base64String.count)")
        
        return base64String
    }
}
