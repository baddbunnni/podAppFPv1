//
//  LoadView.swift
//  podAppFPv1.00
//
//  Created by S R on 3/6/26.
//

import SwiftUI

struct LoadView: View {
    
    @State private var goToContentView = false
    
    var body: some View {
        
        ZStack {
            
            if goToContentView {
                ContentView()
                    .transition(.opacity)
            } else {
                
                Color.black
                    .ignoresSafeArea()
                
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 500)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: goToContentView)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                goToContentView = true
            }
        }
    }
}
