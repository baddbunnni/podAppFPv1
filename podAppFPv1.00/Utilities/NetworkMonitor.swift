//
//  NetworkMonitor.swift
//  podAppFPv1.00
//
//  Created by S R on 4/17/26.
//

import Network
import OSLog
import Combine

final class NetworkMonitor: ObservableObject {
    
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected: Bool = true
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            
            DispatchQueue.main.async {
                self?.isConnected = isConnected
                Logger.device.info("Network status changed: \(isConnected ? "Online" : "Offline")")
            }
        }
        
        monitor.start(queue: queue)
    }
}
