//
//  HeaderView.swift
//  podAppFPv1.00
//
//  Created by S R on 3/27/26.
//

import SwiftUI

struct HeaderView: View {
    
    let selectedTab: ContentView.Tab
    let deviceUUID: String
    let isDeviceLinked: Bool
    
    let onSelectPod: () -> Void
    let onSelectConfig: () -> Void
    
    var body: some View {
        
        HStack(spacing: 12) {
            
            Button(action: {
                onSelectPod()
            }) {
                Text("POD Menu")
                    .font(.headline)
                    .fontWeight(selectedTab == .pod ? .bold : .regular)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == .pod
                        ? AnyShapeStyle(FPTheme.buttonBackground)
                        : AnyShapeStyle(Color.clear)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundColor(.black)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                onSelectConfig()
            }) {
                Text("Configuration")
                    .font(.headline)
                    .fontWeight(selectedTab == .configuration ? .bold : .regular)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == .configuration
                        ? AnyShapeStyle(FPTheme.buttonBackground)
                        : AnyShapeStyle(Color.clear)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundColor(.black)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                
                Text("User: \(isDeviceLinked ? "Linked" : "Not Linked")")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Device: \(deviceUUID.isEmpty ? "Not Set" : deviceUUID)")
                    .font(.subheadline)
                    .foregroundColor(FPTheme.graphite)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }
}
