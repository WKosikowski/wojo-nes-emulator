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

    @State private var folderPath: String = ""

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
                HStack {
                    ZStack {
                        RoundedRectangle(cornerSize: CGSize(width: 20, height: 20))
                            .foregroundColor(.gray.opacity(0.7))

                        VStack(spacing: 20) {
                            HStack(spacing: 30) {
                                // D-pad
                                VStack(spacing: 10) {
                                    Text("D-Pad")
                                        .font(.headline)
                                    VStack(spacing: 5) {
                                        ControllerButton(button: .up, isSelected: selectedButton == .up, action: { selectButton(.up) })
                                        HStack(spacing: 5) {
                                            ControllerButton(button: .left, isSelected: selectedButton == .left, action: { selectButton(.left) })
                                            Spacer().frame(width: 30, height: 30)
                                            ControllerButton(button: .right, isSelected: selectedButton == .right, action: { selectButton(.right) })
                                        }
                                        ControllerButton(button: .down, isSelected: selectedButton == .down, action: { selectButton(.down) })
                                    }
                                    .padding(12)
                                    .background(Color.gray)
                                    .cornerRadius(10)
                                }

                                // Select/Start
                                VStack(spacing: 10) {
                                    Text("Select/Start")
                                        .font(.headline)
                                    VStack(spacing: 8) {
                                        ControllerButton(button: .select, isSelected: selectedButton == .select, action: { selectButton(.select) })
                                        ControllerButton(button: .start, isSelected: selectedButton == .start, action: { selectButton(.start) })
                                    }
                                    .padding(12)
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
                                            Text("A")
                                                .font(.caption)
                                        }
                                        VStack(spacing: 5) {
                                            ControllerButton(button: .b, isSelected: selectedButton == .b, action: { selectButton(.b) })
                                            Text("B")
                                                .font(.caption)
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.gray)
                                    .cornerRadius(10)
                                }
                            }
                            Spacer()
                        }
                        .padding(20)
                    }
                    .frame(width: 550, height: 170)
                }.padding()

                // Emulator Controls (below controller)
                HStack(spacing: 20) {
                    Text("Emulator Controls")
                        .font(.headline)
                    HStack(spacing: 8) {
                        Text("Pause:")
                        ControllerButton(button: .pause, isSelected: selectedButton == .pause, action: { selectButton(.pause) })
                    }
                    HStack(spacing: 8) {
                        Text("Screenshot:")
                        ControllerButton(button: .screenshot, isSelected: selectedButton == .screenshot, action: { selectButton(.screenshot) })
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.5))
                .cornerRadius(10)

                // Display Options
                VStack(spacing: 12) {
                    Text("Display Options")
                        .font(.headline)
                    Toggle("Show FPS Counter", isOn: $viewModel.showFPS)
                        .toggleStyle(.checkbox)
                }
                .padding(12)
                .background(Color.gray.opacity(0.5))
                .cornerRadius(10)

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

        VStack(alignment: .leading) {
            Text("Screenshot Destination Folder Path")
            HStack(spacing: 12) {
                TextField("Enter folder path…", text: $folderPath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minWidth: 400)
                    .disabled(true)

                Button("Browse…") {
                    openFolderPicker()
                }
            }
        }
        .padding()
    }

    // MARK: Functions

    private func selectButton(_ button: NESButton) {
        selectedButton = button
        isCapturingKey = true
    }

    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"

        if panel.runModal() == .OK {
            if let url = panel.url {
                folderPath = url.path
            }
        }
    }
}
