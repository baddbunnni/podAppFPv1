//
//  SignatureCanvas.swift
//  podAppFPv1.00
//
//  Created by S R on 3/27/26.
//

import SwiftUI

struct SignatureCanvas: View {
    
    let lines: [[CGPoint]]
    let currentLine: [CGPoint]
    
    var body: some View {
        Canvas { context, size in
            for line in lines {
                var path = Path()
                
                if let firstPoint = line.first {
                    path.move(to: firstPoint)
                    for point in line.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(path, with: .color(.black), lineWidth: 3)
                }
            }
            
            var currentPath = Path()
            if let firstPoint = currentLine.first {
                currentPath.move(to: firstPoint)
                for point in currentLine.dropFirst() {
                    currentPath.addLine(to: point)
                }
                context.stroke(currentPath, with: .color(.black), lineWidth: 3)
            }
        }
    }
}
