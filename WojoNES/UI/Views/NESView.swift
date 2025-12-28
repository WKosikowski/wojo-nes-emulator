//
//  NESView.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 23/12/2025.
//

import CoreVideo
import Foundation
import MetalKit
import SwiftUI

/// The main view controller for the NES emulator interface.
/// Displays the emulator output via Metal rendering and provides an overlay menu bar.
/// The menu bar is context-sensitive, appearing only when the user moves the mouse
/// and disappearing after 5 seconds of inactivity.
struct NESView: View {
    // MARK: SwiftUI Properties

    /// The view model managing emulator state and operations
    @StateObject private var viewModel = NESViewModel()
    /// Tracks whether the emulator is currently running
    @State private var isRunning = false
    /// Controls visibility of the overlay menu bar
    @State private var showMenu = false
    /// Timer used to automatically hide the menu after inactivity
    @State private var hideMenuTimer: Timer?

    // MARK: Content Properties

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Full-screen Metal bitmap view rendering the emulator output
            MetalBitmapView(pixmap: viewModel.pixelMap) { controller in
                viewModel.nesControllerEvent(controller: controller)
            }
            .ignoresSafeArea()
            // Show and reset the hide timer when the mouse is moving
            .onContinuousHover { phase in
                switch phase {
                    case .active:
                        showMenu = true
                        resetHideMenuTimer()

                    case .ended:
                        // Start the timer when mouse stops moving
                        resetHideMenuTimer()
                }
            }

            // Overlay menu bar positioned in the top-left corner
            // Only displayed when the user is actively moving the mouse
            if showMenu {
                MenuBarView(isRunning: $isRunning, viewModel: viewModel)
                    .padding(16)
                    .transition(.opacity)
            }

            // Error message overlay displayed when an error occurs
            // Appears in the top-left area with a semi-transparent red background
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding()
                    Spacer()
                }
            }
        }
        // Maintain the NES aspect ratio (256:240) when scaling the window
        .aspectRatio(CGSize(width: 256, height: 240), contentMode: .fit)
        // Clean up resources when the view disappears
        .onDisappear {
            hideMenuTimer?.invalidate()
        }
    }

    // MARK: Functions

    /// Resets the hide menu timer to 5 seconds.
    /// When the timer expires, the menu bar will fade out.
    /// If called whilst a timer is already running, it cancels the existing timer first.
    private func resetHideMenuTimer() {
        hideMenuTimer?.invalidate()
        hideMenuTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation {
                showMenu = false
            }
        }
    }
}
