//
//  ScanSessionStore.swift
//  podAppFPv1.00
//
//  Created by S R on 4/10/26.
//

import Foundation
import OSLog

enum ScanSessionStore {
    
    private static let sessionKey = "activeScanSession"
    
    static func save(_ session: ActiveScanSession) {
        let shouldClear =
            session.selectedScanType == nil &&
            session.scannedItems.isEmpty &&
            session.vehicleRegistration.isEmpty &&
            session.selectedCourier.isEmpty &&
            session.scannedAWB.isEmpty &&
            session.retrySignatureBase64 == nil
        
        if shouldClear {
            clear()
            return
        }
        
        do {
            let data = try JSONEncoder().encode(session)
            UserDefaults.standard.set(data, forKey: sessionKey)
            Logger.scan.info("Active scan session saved")
            Logger.scan.info("Saved scan count: \(session.scannedItems.count)")
        } catch {
            Logger.scan.error("Failed to save active scan session: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    static func load() -> ActiveScanSession? {
        guard let data = UserDefaults.standard.data(forKey: sessionKey) else {
            Logger.scan.info("No saved active scan session found")
            return nil
        }
        
        do {
            let session = try JSONDecoder().decode(ActiveScanSession.self, from: data)
            Logger.scan.info("Active scan session restored")
            Logger.scan.info("Restored scan count: \(session.scannedItems.count)")
            return session
        } catch {
            Logger.scan.error("Failed to load active scan session: \(error.localizedDescription, privacy: .public)")
            clear()
            return nil
        }
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
        Logger.scan.info("Active scan session cleared")
    }
}
