//
//  ControllerConfigView.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 28/12/2025.
//

import SwiftUI

// import AppKit

struct ControllerConfigView: View {
    // MARK: SwiftUI Properties

    @EnvironmentObject var viewModel: NESViewModel

    @State private var selectedButton: NESButton?
    @State private var isCapturingKey = false

    // MARK: Content Properties

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Configure NES Controller")
                    .font(.title)

                // Controller layout (unchanged)
                ZStack {
                    RoundedRectangle(cornerSize: CGSize(width: 20, height: 20))
                        .foregroundColor(.gray.opacity(0.7))
                        .frame(width: 420, height: 160)

                    HStack(spacing: 20) {
                        // D-pad
                        VStack {
                            Text("D-Pad")
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(10)
                                VStack(spacing: 0) {
                                    ControllerButton(button: .up, isSelected: selectedButton == .up, action: { selectButton(.up) })
                                        .frame(width: 30, height: 30)
                                    HStack(spacing: 0) {
                                        ControllerButton(button: .left, isSelected: selectedButton == .left, action: { selectButton(.left) })
                                            .frame(width: 30, height: 30)
                                        Spacer().frame(width: 30)
                                        ControllerButton(button: .right, isSelected: selectedButton == .right, action: { selectButton(.right) })
                                            .frame(width: 30, height: 30)
                                    }
                                    ControllerButton(button: .down, isSelected: selectedButton == .down, action: { selectButton(.down) })
                                        .frame(width: 30, height: 30)
                                }
                            }
                        }

                        // Select/Start
                        VStack {
                            Text("Select/Start")
                            HStack(spacing: 10) {
                                ControllerButton(button: .select, isSelected: selectedButton == .select, action: { selectButton(.select) })
                                    .frame(width: 50, height: 20)
                                ControllerButton(button: .start, isSelected: selectedButton == .start, action: { selectButton(.start) })
                                    .frame(width: 50, height: 20)
                            }
                            .padding()
                            .background(Color.gray)
                            .cornerRadius(5)
                        }

                        // A/B buttons
                        VStack {
                            Text("A/B Buttons")
                            HStack(spacing: 10) {
                                ControllerButton(button: .a, isSelected: selectedButton == .a, action: { selectButton(.a) })
                                    .frame(width: 30, height: 30)
                                    .background(Circle().fill(Color.red))
                                ControllerButton(button: .b, isSelected: selectedButton == .b, action: { selectButton(.b) })
                                    .frame(width: 30, height: 30)
                                    .background(Circle().fill(Color.red))
                            }
                            .padding()
                            .background(Color.gray)
                            .cornerRadius(10)
                        }
                    }
                }
                // Key capture prompt
                if isCapturingKey, let button = selectedButton {
                    Text("Press a key for \(button.rawValue)")
                        .foregroundColor(.blue)
                } else {
                    Text("Select the key for customisation.")
                }
            }

            // Key capture view, always present but only focused when capturing
            KeyCaptureView(isCapturing: $isCapturingKey, selectedButton: $selectedButton)
                .frame(width: 0, height: 0) // Invisible, but in view hierarchy
                .focusable()
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }

    // MARK: Functions

    private func selectButton(_ button: NESButton) {
        selectedButton = button
        isCapturingKey = true
    }
}
