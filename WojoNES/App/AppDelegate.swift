//
//  AppDelegate.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 23/12/2025.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    @objc
    func showSecondWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows
            .first { $0.title == "Options" }?
            .makeKeyAndOrderFront(nil)
    }
}
