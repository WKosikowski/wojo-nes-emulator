//
//  AppDelegate.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 23/12/2025.
//

import AppKit
import SwiftUI

extension Notification.Name {
    static let openOptionsWindow = Notification.Name("openOptionsWindow")
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    @objc
    func showSecondWindow() {
        NSApp.activate(ignoringOtherApps: true)

        // First, try to find and bring forward an existing Options window
        if let existingWindow = NSApp.windows.first(where: { $0.title == "Options" }) {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        // Post notification to request window opening
        NotificationCenter.default.post(name: .openOptionsWindow, object: nil)
    }
}
