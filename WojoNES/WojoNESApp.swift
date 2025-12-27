//
//  WojoNESApp.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 11/05/2025.
//

import SwiftUI

// MARK: - Windows

enum Windows {
    case main
    case options

    // MARK: Computed Properties

    var title: String {
        switch self {
            case .main:
                return "WojoNES"
            case .options:
                return "Options"
        }
    }

    var identifier: String {
        switch self {
            case .main:
                return "main"
            case .options:
                return "second"
        }
    }

    var keyboardShortcut: KeyEquivalent {
        switch self {
            case .main:
                return "1"
            case .options:
                return "2"
        }
    }
}

// MARK: - WojoNESApp

@main
struct WojoNESApp: App {
    // MARK: SwiftUI Properties

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: Computed Properties

    var body: some Scene {
        WindowGroup(Windows.main.title) {
            NESView()
                .frame(minWidth: 400, minHeight: 400)
        }
        .windowStyle(.hiddenTitleBar)
    }

    var commands: some Commands {
        CommandGroup(after: .sidebar) {
            Button(Windows.options.title) {
                NSApp.sendAction(#selector(AppDelegate.showSecondWindow), to: nil, from: nil)
            }
            .keyboardShortcut(
                Windows.options.keyboardShortcut,
                modifiers: [.command]
            )
        }
    }
}
