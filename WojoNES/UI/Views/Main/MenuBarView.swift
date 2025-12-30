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

    /// Reference to the view model for coordinating emulator actions
    @ObservedObject var viewModel: NESViewModel

    // MARK: Content Properties

    var body: some View {
        VStack(spacing: 12) {
            // Load ROM button — opens the file picker to select a NES ROM
            MenuButton(icon: "folder.fill", label: "Load ROM", action: {
                viewModel.loadROM()
            })

            // Pause/Resume button — toggles emulation state
            // Icon and label change based on current emulator state
            MenuButton(
                icon: viewModel.emulatorState == .running ? "pause.fill" : "play.fill",
                label: viewModel.emulatorState == .running ? "Pause" : "Resume",
                action: {
                    if viewModel.emulatorState == .running {
                        viewModel.pause()
                    } else {
                        viewModel.resume()
                    }
                }
            )

            // Save State button — saves the current emulator state to a .wnes file
            MenuButton(icon: "square.and.arrow.down.fill", label: "Save State", action: {
                viewModel.saveState()
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
