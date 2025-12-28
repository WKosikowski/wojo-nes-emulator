

/// Represents the state of an NES controller with 8 buttons.
///
/// This class tracks the pressed state of all NES controller buttons
/// and provides conversion to byte format for emulator input.
/// Supports dynamic key binding configuration via string-based key identifiers.
final class NESController: KeyboardMappableController {
    // MARK: Properties

    var a: Bool = false // A button
    var b: Bool = false // B button
    var select: Bool = false // Select button
    var start: Bool = false // Start button
    var up: Bool = false // D-pad Up
    var down: Bool = false // D-pad Down
    var left: Bool = false // D-pad Left
    var right: Bool = false // D-pad Right

    /// Mapping from button names to key strings (e.g., "Return" → start button)
    /// Users can customise these key bindings
    private var keyBindings: [String: String] = [:] {
        didSet {
            updateKeyCodeBindings()
        }
    }

    /// Inverse mapping: from key codes (as strings) to button names
    /// Used for quick lookup when processing keyboard events
    private var keyCodeToButton: [String: NESButton] = [:]

    // MARK: Lifecycle

    init() {
        loadDefaultKeyBindings()
    }

    // MARK: Functions

    /// Convert to a byte for emulator input (if needed)
    func toByte() -> UInt8 {
        (a ? 0x01 : 0) |
            (b ? 0x02 : 0) |
            (select ? 0x04 : 0) |
            (start ? 0x08 : 0) |
            (up ? 0x10 : 0) |
            (down ? 0x20 : 0) |
            (left ? 0x40 : 0) |
            (right ? 0x80 : 0)
    }

    /// Sets the key binding for a specific NES button
    /// - Parameters:
    ///   - button: The NES button to bind
    ///   - key: The keyboard key string (e.g., "Return", "Space", "x", "z")
    func setKeyBinding(button: NESButton, key: String) {
        let buttonName = buttonName(for: button)
        keyBindings[buttonName] = key
        print("[NESController] Set binding: \(buttonName) -> \(key)")
    }

    /// Gets the current key binding for a specific NES button
    /// - Parameter button: The NES button to query
    /// - Returns: The keyboard key string, or the default if not customised
    func getKeyBinding(button: NESButton) -> String {
        let buttonName = buttonName(for: button)
        let binding = keyBindings[buttonName] ?? getDefaultKeyBinding(for: button)
        print("[NESController] Get binding: \(buttonName) -> \(binding)")
        return binding
    }

    // MARK: - KeyboardMappableController

    /// Updates the controller state based on a keyboard key event.
    /// Converts the key string from the event to the appropriate button binding.
    ///
    /// - Parameters:
    ///   - keyCode: The macOS key code from NSEvent
    ///   - isPressed: Whether the key is pressed (true) or released (false)
    func updateState(keyCode: UInt16, isPressed: Bool) {
        // Convert key code to string representation
        // This is a simplified approach; for production, use a proper key translation
        let keyString = keyStringFromCode(keyCode)

        // Look up which button this key is bound to
        if let button = keyCodeToButton[keyString.lowercased()] {
            setButtonState(button, isPressed: isPressed)
        }
    }

    /// Loads the default key bindings (Return, Space, X, Z, arrow keys)
    private func loadDefaultKeyBindings() {
        keyBindings = [
            "start": "Return",
            "select": "Space",
            "a": "x",
            "b": "z",
            "up": "Up",
            "down": "Down",
            "left": "Left",
            "right": "Right",
        ]
        updateKeyCodeBindings()
    }

    /// Updates the key code lookup table when bindings change
    private func updateKeyCodeBindings() {
        keyCodeToButton = [:]
        for (buttonName, keyString) in keyBindings {
            if let button = buttonFromName(buttonName) {
                keyCodeToButton[keyString.lowercased()] = button
            }
        }
    }

    /// Gets the default key binding for a button
    private func getDefaultKeyBinding(for button: NESButton) -> String {
        switch button {
            case .a: return "a"
            case .b: return "b"
            case .select: return "Space"
            case .start: return "Return"
            case .up: return "Up"
            case .down: return "Down"
            case .left: return "Left"
            case .right: return "Right"
        }
    }

    /// Converts a button enum to a string name
    private func buttonName(for button: NESButton) -> String {
        switch button {
            case .a: return "a"
            case .b: return "b"
            case .select: return "select"
            case .start: return "start"
            case .up: return "up"
            case .down: return "down"
            case .left: return "left"
            case .right: return "right"
        }
    }

    /// Converts a button string name to a button enum
    private func buttonFromName(_ name: String) -> NESButton? {
        switch name {
            case "a": return .a
            case "b": return .b
            case "select": return .select
            case "start": return .start
            case "up": return .up
            case "down": return .down
            case "left": return .left
            case "right": return .right
            default: return nil
        }
    }

    /// Updates the state of a specific button
    private func setButtonState(_ button: NESButton, isPressed: Bool) {
        switch button {
            case .a: a = isPressed
            case .b: b = isPressed
            case .select: select = isPressed
            case .start: start = isPressed
            case .up: up = isPressed
            case .down: down = isPressed
            case .left: left = isPressed
            case .right: right = isPressed
        }
    }

    /// Converts a macOS key code to a readable string representation.
    /// Supports all standard keyboard keys including letters, numbers, symbols, and special keys.
    /// - Parameter keyCode: The macOS key code from NSEvent
    /// - Returns: A readable string representation of the key
    private func keyStringFromCode(_ keyCode: UInt16) -> String {
        let keyCodeMap: [UInt16: String] = [
            // Number row
            18: "1", 19: "2", 20: "3", 21: "4", 23: "5",
            22: "6", 26: "7", 28: "8", 25: "9", 29: "0",

            // Top letter row (QWERTY)
            12: "q", 13: "w", 14: "e", 15: "r", 17: "t",
            16: "y", 32: "u", 34: "i", 31: "o", 35: "p",

            // Middle letter row (ASDFGH)
            0: "a", 1: "s", 2: "d", 3: "f", 5: "g",
            4: "h", 38: "j", 40: "k", 37: "l",

            // Bottom letter row (ZXCVBN)
            6: "z", 7: "x", 8: "c", 9: "v", 11: "b",
            45: "n", 46: "m",

            // Special keys
            36: "Return", 49: "Space", 48: "Tab", 53: "Escape",
            51: "Backspace", 117: "Delete", 123: "Left", 124: "Right",
            126: "Up", 125: "Down", 116: "PageUp", 121: "PageDown",
            115: "Home", 119: "End",

            // Function keys
            122: "F1", 120: "F2", 99: "F3", 118: "F4",
            96: "F5", 97: "F6", 98: "F7", 100: "F8",
            101: "F9", 109: "F10", 103: "F11", 111: "F12",

            // Symbol keys
            27: "-", 24: "+", 41: ";", 39: "'", 43: ",",
            47: ".", 44: "/", 50: "`", 33: "[", 30: "]",
            42: "\\",

            // Modifier keys (for reference, not typically bound)
            55: "Cmd", 56: "Shift", 58: "Alt", 59: "Ctrl",
        ]

        // Return mapped value or generic identifier for unknown keys
        return keyCodeMap[keyCode] ?? "Key_\(keyCode)"
    }
}
