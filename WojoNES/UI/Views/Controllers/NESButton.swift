//
//  NESButton.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 23/12/2025.
//

import AppKit
import SwiftUI

// MARK: - NESButton

/// NES button enum (matches Class Diagram)
enum NESButton: String, CaseIterable {
    case a = "A"
    case b = "B"
    case select = "Select"
    case start = "Start"
    case up = "Up"
    case down = "Down"
    case left = "Left"
    case right = "Right"
    // Emulator controls (not part of NES controller)
    case pause = "Pause"
    case screenshot = "Screenshot"

    // MARK: Static Computed Properties

    /// Returns only the NES controller buttons (excludes emulator controls)
    static var controllerButtons: [NESButton] {
        allCases.filter(\.isControllerButton)
    }

    /// Returns only the emulator control buttons
    static var emulatorControls: [NESButton] {
        allCases.filter { !$0.isControllerButton }
    }

    // MARK: Computed Properties

    /// Returns true if this is an actual NES controller button (not an emulator control)
    var isControllerButton: Bool {
        switch self {
            case .a,
                 .b,
                 .select,
                 .start,
                 .up,
                 .down,
                 .left,
                 .right:
                return true
            case .pause,
                 .screenshot:
                return false
        }
    }
}

// MARK: - Controller

/// Extend Controller for key bindings
/// Controller class implementation
class Controller {
    // MARK: Properties

    /// Button states (true = pressed): A, B, Select, Start, Up, Down, Left, Right
    private(set) var buttons: [Bool] = Array(repeating: false, count: 8)

    /// Shift register for serial reading (NES hardware behavior)
    private var shiftRegister: UInt8 = 0
    /// Tracks if strobe is active (1 = latch buttons, 0 = shift)
    private var isStrobeActive: Bool = false

    // MARK: Computed Properties

    /// Key bindings (NESButton to keyboard key, e.g., A: "z")
    private var keyBindings: [NESButton: String] {
        get {
            if let bindings = UserDefaults.standard.dictionary(forKey: "NESKeyBindings") as? [String: String] {
                return bindings.reduce(into: [NESButton: String]()) { result, pair in
                    if let button = NESButton(rawValue: pair.key) {
                        result[button] = pair.value
                    }
                }
            }
            // Default bindings
            return [
                .a: "z",
                .b: "x",
                .select: "c",
                .start: "v",
                .up: "ArrowUp",
                .down: "ArrowDown",
                .left: "ArrowLeft",
                .right: "ArrowRight",
                .pause: "Escape",
                .screenshot: "F12",
            ]
        }
        set {
            let bindings = newValue.reduce(into: [String: String]()) { result, pair in
                result[pair.key.rawValue] = pair.value
            }
            UserDefaults.standard.set(bindings, forKey: "NESKeyBindings")
        }
    }

    // MARK: Lifecycle

    /// Initialize with default state
    init() {
        latchButtons() // Initialize shift register with current button states
    }

    // MARK: Functions

    /// Read input from 0x4016 (controller 1)
    func readInput() -> UInt8 {
        if isStrobeActive {
            // Strobe active: return A button state (bit 0)
            latchButtons()
            return buttons[0] ? 1 : 0
        } else {
            // Strobe inactive: shift out next bit
            let value = shiftRegister & 1
            shiftRegister >>= 1
            // Set high bit to 1 after 8 shifts (NES behavior)
            if shiftRegister == 0 {
                shiftRegister = 0xFF
            }
            return UInt8(value)
        }
    }

    /// Write strobe to 0x4016
    func writeStrobe(value: UInt8) {
        let newStrobe = (value & 1) == 1
        if isStrobeActive, !newStrobe {
            // Falling edge (1 -> 0): latch buttons
            latchButtons()
        }
        isStrobeActive = newStrobe
    }

    /// Update button states based on keyboard input
    func updateButtons(key: String, isPressed: Bool) {
        var newButtons = buttons
        for button in NESButton.controllerButtons {
            if keyBindings[button] == key, let index = buttonIndex(button) {
                newButtons[index] = isPressed
            }
        }
        buttons = newButtons
        if isStrobeActive {
            latchButtons() // Update shift register during strobe
        }
    }

    /// Set key binding for a button
    func setKeyBinding(button: NESButton, key: String) {
        var bindings = keyBindings
        bindings[button] = key
        keyBindings = bindings
    }

    /// Get key binding for a button
    func getKeyBinding(button: NESButton) -> String {
        keyBindings[button] ?? "None"
    }

    // Helper: Latch button states into shift register
    private func latchButtons() {
        shiftRegister = 0
        for (index, isPressed) in buttons.enumerated() {
            if isPressed {
                shiftRegister |= UInt8(1 << index)
            }
        }
    }

    // Helper: Map NESButton to button array index
    // Returns nil for emulator controls (pause, screenshot) as they're not controller buttons
    private func buttonIndex(_ button: NESButton) -> Int? {
        switch button {
            case .a: return 0
            case .b: return 1
            case .select: return 2
            case .start: return 3
            case .up: return 4
            case .down: return 5
            case .left: return 6
            case .right: return 7
            case .pause,
                 .screenshot: return nil
        }
    }
}
