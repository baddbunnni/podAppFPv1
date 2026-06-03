//
//  SignatureCaptureOverlay.swift
//  podAppFPv1.00
//
//  Created by S R on 3/27/26.
//

import SwiftUI
import OSLog

struct SignatureCaptureOverlay: View {
    
    var onBack: () -> Void
    var onSave: (String) -> Void
    
    @State private var lines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []
    
    private let canvasWidth = UIScreen.main.bounds.width * 0.88
    private let canvasHeight = UIScreen.main.bounds.height * 0.65
    
    private var hasSignature: Bool {
        !lines.isEmpty || !currentLine.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            
            ZStack(alignment: .topTrailing) {
                
                VStack(spacing: 0) {
                    
                    Text("Please sign here")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 18)
                        .padding(.horizontal, 22)
                    
                    ZStack {
                        SignatureCanvas(lines: lines, currentLine: currentLine)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    
                    HStack {
                        
                        Button("Clear") {
                            lines = []
                            currentLine = []
                        }
                        .padding(.horizontal, 26)
                        .padding(.vertical, 14)
                        .background(FPTheme.secondaryButtonBackground)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .disabled(!hasSignature)
                        
                        Spacer()
                        
                        Button("UPLOAD POD") {
                            guard hasSignature else {
                                Logger.upload.error("Upload blocked: no signature captured")
                                return
                            }
                            
                            guard let base64Signature = SignatureExporter.exportBase64PNG(
                                lines: lines,
                                currentLine: currentLine,
                                size: CGSize(width: canvasWidth, height: canvasHeight)
                            ) else {
                                Logger.upload.error("Signature export failed")
                                return
                            }
                            
                            onSave(base64Signature)
                        }
                        .padding(.horizontal, 26)
                        .padding(.vertical, 14)
                        .background(FPTheme.buttonBackground)
                        .foregroundColor(FPTheme.buttonText)
                        .shadow(
                            color: FPTheme.softShadow,
                            radius: 6,
                            x: 0,
                            y: 3
                        )
                        .cornerRadius(10)
                        .disabled(!hasSignature)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 18)
                }
                .frame(width: canvasWidth, height: canvasHeight)
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            currentLine.append(value.location)
                        }
                        .onEnded { _ in
                            if !currentLine.isEmpty {
                                lines.append(currentLine)
                                currentLine = []
                            }
                        }
                )
                
                Button(action: {
                    onBack()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
                .offset(x: 16, y: -16)
            }
        }
    }
}
