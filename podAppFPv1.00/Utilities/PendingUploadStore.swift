//
//  PendingUploadStore.swift
//  podAppFPv1.00
//
//  Created by S R on 4/10/26.
//

import Foundation
import OSLog

enum PendingUploadStore {
    
    private static let pendingUploadKey = "pendingUploadQueue"
    
    static func save(_ pendingUpload: PendingUpload) {
        var queue = loadAll()
        queue.append(pendingUpload)
        saveAll(queue)
        Logger.upload.info("Pending upload added to queue")
        Logger.upload.info("Pending queue count: \(queue.count)")
    }
    
    static func loadAll() -> [PendingUpload] {
        guard let data = UserDefaults.standard.data(forKey: pendingUploadKey) else {
            Logger.upload.info("No pending upload queue found")
            return []
        }
        
        do {
            let queue = try JSONDecoder().decode([PendingUpload].self, from: data)
            Logger.upload.info("Pending upload queue restored")
            Logger.upload.info("Pending queue count: \(queue.count)")
            return queue
        } catch {
            Logger.upload.error("Failed to load pending upload queue: \(error.localizedDescription, privacy: .public)")
            clear()
            return []
        }
    }
    
    static func remove(id: UUID) {
        let updated = loadAll().filter { $0.id != id }
        saveAll(updated)
        Logger.upload.info("Pending upload removed from queue")
        Logger.upload.info("Pending queue count: \(updated.count)")
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: pendingUploadKey)
        Logger.upload.info("Pending upload queue cleared")
    }
    
    private static func saveAll(_ queue: [PendingUpload]) {
        do {
            let data = try JSONEncoder().encode(queue)
            UserDefaults.standard.set(data, forKey: pendingUploadKey)
        } catch {
            Logger.upload.error("Failed to save pending upload queue: \(error.localizedDescription, privacy: .public)")
        }
    }
}
