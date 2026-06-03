//
//  Theme.swift
//  podAppFPv1.00
//
//  Created by S R on 5/22/26.
//

import SwiftUI

enum FPTheme {
    
    // MARK: - Core Brand Colours
    
    static let brandYellow = Color(
        red: 0.96,
        green: 0.74,
        blue: 0.00
    )
    
    static let brandOrange = Color(
        red: 0.93,
        green: 0.58,
        blue: 0.00
    )
    
    static let graphite = Color(
        red: 0.43,
        green: 0.43,
        blue: 0.46
    )
    
    static let darkGraphite = Color(
        red: 0.18,
        green: 0.18,
        blue: 0.20
    )
    
    static let background = Color(
        red: 0.96,
        green: 0.97,
        blue: 0.98
    )
    
    static let cardBackground = Color.white
    
    static let subtleBorder = Color.gray.opacity(0.18)
    
    // MARK: - Status Colours
    
    static let success = Color.green
    
    static let warning = Color.orange
    
    static let danger = Color.red
    
    // MARK: - Gradients
    
    static let primaryGradient = LinearGradient(
        colors: [
            brandOrange,
            brandYellow
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkGradient = LinearGradient(
        colors: [
            darkGraphite,
            graphite
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [
            Color.white,
            Color(
                red: 0.985,
                green: 0.985,
                blue: 0.99
            )
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Shadows
    
    static let softShadow = Color.black.opacity(0.08)
    
    static let strongShadow = Color.black.opacity(0.16)
    
    // MARK: - Button Styles

    static let buttonBackground = primaryGradient

    static let buttonText = Color.black

    static let secondaryButtonBackground = Color(
        red: 0.90,
        green: 0.90,
        blue: 0.92
    )

    static let disabledButtonBackground = Color.gray.opacity(0.25)
}
