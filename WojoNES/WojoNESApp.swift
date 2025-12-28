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

    @StateObject var viewModel: NESViewModel = .init()

    // MARK: Computed Properties

    var body: some Scene {
        WindowGroup(Windows.main.title) {
            NESView()
                .frame(minWidth: 400, minHeight: 400)
        }
        .windowStyle(.hiddenTitleBar)

        Window(Windows.options.title, id: Windows.options.identifier) {
            ControllerConfigView()
                .environmentObject(viewModel)
        }
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

// MARK: - SecondView

struct SecondView: View {
    var body: some View {
        Text("This is the second window")
            .frame(width: 300, height: 200)
            .padding()
    }
}
