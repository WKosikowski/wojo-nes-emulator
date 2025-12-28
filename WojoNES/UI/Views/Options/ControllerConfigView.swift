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

                // Controller layout
                ZStack {
                    RoundedRectangle(cornerSize: CGSize(width: 20, height: 20))
                        .foregroundColor(.gray.opacity(0.7))
                        .frame(maxWidth: .infinity, minHeight: 350)

                    VStack(spacing: 20) {
                        HStack(spacing: 30) {
                            // D-pad
                            VStack(spacing: 10) {
                                Text("D-Pad")
                                    .font(.headline)
                                ZStack {
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(width: 140, height: 140)
                                        .cornerRadius(10)
                                    VStack(spacing: 5) {
                                        ControllerButton(button: .up, isSelected: selectedButton == .up, action: { selectButton(.up) })
                                            .frame(height: 40)
                                        HStack(spacing: 5) {
                                            ControllerButton(button: .left, isSelected: selectedButton == .left, action: { selectButton(.left) })
                                                .frame(height: 40)
                                            Spacer().frame(width: 40)
                                            ControllerButton(button: .right, isSelected: selectedButton == .right, action: { selectButton(.right) })
                                                .frame(height: 40)
                                        }
                                        ControllerButton(button: .down, isSelected: selectedButton == .down, action: { selectButton(.down) })
                                            .frame(height: 40)
                                    }
                                    .padding(10)
                                }
                            }

                            // Select/Start
                            VStack(spacing: 10) {
                                Text("Select/Start")
                                    .font(.headline)
                                VStack(spacing: 10) {
                                    ControllerButton(button: .select, isSelected: selectedButton == .select, action: { selectButton(.select) })
                                        .frame(height: 50)
                                    ControllerButton(button: .start, isSelected: selectedButton == .start, action: { selectButton(.start) })
                                        .frame(height: 50)
                                }
                                .padding()
                                .background(Color.gray)
                                .cornerRadius(10)
                            }

                            // A/B buttons
                            VStack(spacing: 10) {
                                Text("A/B Buttons")
                                    .font(.headline)
                                HStack(spacing: 15) {
                                    VStack(spacing: 5) {
                                        ControllerButton(button: .a, isSelected: selectedButton == .a, action: { selectButton(.a) })
                                            .frame(height: 50)
                                        Text("A")
                                            .font(.caption)
                                    }
                                    VStack(spacing: 5) {
                                        ControllerButton(button: .b, isSelected: selectedButton == .b, action: { selectButton(.b) })
                                            .frame(height: 50)
                                        Text("B")
                                            .font(.caption)
                                    }
                                }
                                .padding()
                                .background(Color.gray)
                                .cornerRadius(10)
                            }
                        }
                        Spacer()
                    }
                    .padding(20)
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
        .frame(minWidth: 1000, minHeight: 500)
    }

    // MARK: Functions

    private func selectButton(_ button: NESButton) {
        selectedButton = button
        isCapturingKey = true
    }
}
