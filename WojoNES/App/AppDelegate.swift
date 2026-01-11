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
    static let appWillTerminate = Notification.Name("appWillTerminate")
}

// MARK: - MainWindowDelegate

class MainWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Post notification to trigger auto-save
        NotificationCenter.default.post(name: .appWillTerminate, object: nil)

        // Quit the app when the main window is closed
        NSApp.terminate(nil)
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: Properties

    private let mainWindowDelegate = MainWindowDelegate()

    // MARK: Functions

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Find the main window and set its delegate
        if let mainWindow = NSApp.windows.first(where: { $0.title == "WojoNES" }) {
            mainWindow.delegate = mainWindowDelegate
        }
    }

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
