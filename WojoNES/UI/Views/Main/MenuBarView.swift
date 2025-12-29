//
//  MenuBarView.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 28/12/2025.
//

import SwiftUI

/// The vertical menu bar displayed as an overlay on the emulator window.
/// This menu appears on mouse movement and disappears after 5 seconds of inactivity.
/// Provides quick access to core functions: Load ROM, Pause/Resume, and Settings.
struct MenuBarView: View {
    // MARK: SwiftUI Properties

    /// Binding to track whether the emulator is currently running
    @Binding var isRunning: Bool

    // MARK: Properties

    /// Reference to the view model for coordinating emulator actions
    let viewModel: NESViewModel

    // MARK: Content Properties

    var body: some View {
        VStack(spacing: 12) {
            // Load ROM button — opens the file picker to select a NES ROM
            MenuButton(icon: "folder.fill", label: "Load ROM", action: {
                viewModel.loadROM()
            })

            // Pause/Resume button — toggles emulation state
            // Icon and label change based on current running state
            MenuButton(icon: isRunning ? "pause.fill" : "play.fill", label: isRunning ? "Pause" : "Resume", action: {
                if isRunning {
                    viewModel.pause()
                } else {
                    viewModel.resume()
                }
                isRunning.toggle()
            })

            // Settings button — opens the Options window for controller configuration and display settings
            MenuButton(icon: "gear", label: "Settings", action: {
                NSApp.sendAction(#selector(AppDelegate.showSecondWindow), to: nil, from: nil)
            })
        }
        // Padding around all buttons inside the menu
        .padding(12)
        // Semi-transparent dark background for better contrast over the bitmap
        .background(Color.black.opacity(0.85))
        // Rounded corners for a modern appearance
        .cornerRadius(12)
        // Fix width to content size, allow vertical expansion if needed
        .fixedSize(horizontal: true, vertical: false)
    }
}
