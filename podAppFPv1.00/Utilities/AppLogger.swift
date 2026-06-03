//
//  AppLogger.swift
//  podAppFPv1.00
//
//  Created by S R on 4/10/26.
//

import OSLog

extension Logger {
    static let device = Logger(subsystem: "com.fpgroup.podapp", category: "device")
    static let upload = Logger(subsystem: "com.fpgroup.podapp", category: "upload")
    static let scan = Logger(subsystem: "com.fpgroup.podapp", category: "scan")
}
