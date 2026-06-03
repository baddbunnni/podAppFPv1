//
//  LansdscapeOrientationLock.swift
//  podAppFPv1.00
//
//  Created by S R on 5/20/26.
//

import SwiftUI
import UIKit

struct LandscapeOrientationLock: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> LandscapeOrientationViewController {
        LandscapeOrientationViewController()
    }
    
    func updateUIViewController(_ uiViewController: LandscapeOrientationViewController, context: Context) {}
}

final class LandscapeOrientationViewController: UIViewController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.landscapeLeft, .landscapeRight]
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .landscapeRight
    }
    
    override var shouldAutorotate: Bool {
        true
    }
}
