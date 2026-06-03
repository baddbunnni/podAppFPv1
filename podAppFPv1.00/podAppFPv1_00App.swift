//
//  podAppFPv1_00App.swift
//  podAppFPv1.00
//
//  Created by S R on 3/6/26.
//

import SwiftUI
import UIKit

@main
struct podAppFPv1_00App: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            LoadView()
                .background(
                    LandscapeOrientationLock()
                        .frame(width: 0, height: 0)
                )
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        [.landscapeLeft, .landscapeRight]
    }
}

