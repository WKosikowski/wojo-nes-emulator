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
    @EnvironmentObject var viewModel: NESViewModel

    /// Controls visibility of the overlay menu bar
    @State private var showMenu = false
    /// Timer used to automatically hide the menu after inactivity
    @State private var hideMenuTimer: Timer?

    // MARK: Content Properties

    var body: some View {
        ZStack(alignment: .topLeading) {
            ZStack {
                // Full-screen Metal bitmap view rendering the emulator output
                MetalBitmapView(pixmap: viewModel.pixelMap, controller: viewModel.getController()) { controller in
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

                if viewModel.emulatorState == .paused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.6))
                        )
                }
            }

            // Overlay menu bar positioned in the top-left corner
            // Only displayed when the user is actively moving the mouse
            if showMenu {
                MenuBarView(viewModel: viewModel)
                    .padding(16)
                    .transition(.opacity)
            }

            // FPS display in the top-right corner
            if viewModel.showFPS {
                VStack {
                    HStack {
                        Spacer()
                        Text(String(format: "%.1f FPS", viewModel.fps))
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(6)
                            .padding(16)
                    }
                    Spacer()
                }
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

            // Screenshot feedback camera icon in bottom-left corner
            if viewModel.showScreenshotFeedback {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            .padding(16)
                        Spacer()
                    }
                }
                .transition(.opacity)
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
