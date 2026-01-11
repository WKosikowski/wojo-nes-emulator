

/// Represents the state of an NES controller with 8 buttons.
///
/// This class tracks the pressed state of all NES controller buttons
/// and provides conversion to byte format for emulator input.
/// Supports dynamic key binding configuration via string-based key identifiers.
final class NESController: KeyboardMappableController {
    // MARK: Static Properties

//    | Key          | Symbol                 |
//    |--------------|------------------------|
//    | Arrow keys   | ↑ ↓ ← →                |
//    | Return       | ↩                      |
//    | Space        | ␣                      |
//    | Escape       | ⎋                      |
//    | Tab          | ⇥                      |
//    | Backspace    | ⌫                      |
//    | Delete       | ⌦                      |
//    | Page Up/Down | ⇞ ⇟                    |
//    | Home/End     | ↖ ↘                    |
//    | Command      | ⌘                      |
//    | Shift        | ⇧                      |
//    | Option       | ⌥                      |
//    | Control      | ⌃                      |
//    | Letters      | Uppercase (A, B, C...) |

    /// Static map of macOS key codes to readable string representations
    /// Uses standard keyboard symbols where appropriate
    static let keyCodeMap: [UInt16: String] = [
        // Number row
        18: "1", 19: "2", 20: "3", 21: "4", 23: "5",
        22: "6", 26: "7", 28: "8", 25: "9", 29: "0",

        // Top letter row (QWERTY)
        12: "Q", 13: "W", 14: "E", 15: "R", 17: "T",
        16: "Y", 32: "U", 34: "I", 31: "O", 35: "P",

        // Middle letter row (ASDFGH)
        0: "A", 1: "S", 2: "D", 3: "F", 5: "G",
        4: "H", 38: "J", 40: "K", 37: "L",

        // Bottom letter row (ZXCVBN)
        6: "Z", 7: "X", 8: "C", 9: "V", 11: "B",
        45: "N", 46: "M",

        // Special keys with symbols
        36: "↩", // Return
        49: "␣", // Space
        48: "⇥", // Tab
        53: "⎋", // Escape
        51: "⌫", // Backspace
        117: "⌦", // Delete
        123: "←", // Left arrow
        124: "→", // Right arrow
        126: "↑", // Up arrow
        125: "↓", // Down arrow
        116: "⇞", // Page Up
        121: "⇟", // Page Down
        115: "↖", // Home
        119: "↘", // End

        // Function keys
        122: "F1", 120: "F2", 99: "F3", 118: "F4",
        96: "F5", 97: "F6", 98: "F7", 100: "F8",
        101: "F9", 109: "F10", 103: "F11", 111: "F12",

        // Symbol keys
        27: "-", 24: "+", 41: ";", 39: "'", 43: ",",
        47: ".", 44: "/", 50: "`", 33: "[", 30: "]",
        42: "\\",

        // Modifier keys with symbols
        55: "⌘", // Command
        56: "⇧", // Shift
        58: "⌥", // Option/Alt
        59: "⌃", // Control
    ]

    // MARK: Properties

    var a: Bool = false // A button
    var b: Bool = false // B button
    var select: Bool = false // Select button
    var start: Bool = false // Start button
    var up: Bool = false // D-pad Up
    var down: Bool = false // D-pad Down
    var left: Bool = false // D-pad Left
    var right: Bool = false // D-pad Right

    /// Callback triggered when screenshot key is pressed
    var onScreenshotPressed: (() -> Void)?

    /// Callback triggered when pause key is pressed
    var onPauseToggled: (() -> Void)?

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

    // MARK: Static Functions

    /// Converts a macOS key code to a readable string (static version for external use)
    static func keyCodeToString(_ keyCode: UInt16) -> String {
        keyCodeMap[keyCode] ?? "Key_\(keyCode)"
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

    /// Gets all current key bindings as a dictionary
    /// - Returns: Dictionary mapping button names to key strings
    func getAllKeyBindings() -> [String: String] {
        keyBindings
    }

    /// Sets all key bindings from a dictionary
    /// - Parameter bindings: Dictionary mapping button names to key strings
    func setAllKeyBindings(_ bindings: [String: String]) {
        keyBindings = bindings
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

        #if DEBUG
            print("[NESController] Key event: \(keyString) (code: \(keyCode)) - \(isPressed ? "pressed" : "released")")
        #endif

        // Look up which button this key is bound to
        if let button = keyCodeToButton[keyString.lowercased()] {
            #if DEBUG
                print("[NESController] Mapped to button: \(button.rawValue)")
            #endif

            // Handle emulator controls
            if isPressed {
                switch button {
                    case .screenshot:
                        #if DEBUG
                            print("[NESController] Screenshot button pressed, callback: \(onScreenshotPressed != nil)")
                        #endif
                        onScreenshotPressed?()
                        return

                    case .pause:
                        #if DEBUG
                            print("[NESController] Pause button pressed")
                        #endif
                        onPauseToggled?()
                        return

                    default:
                        break
                }
            }

            // Handle NES controller buttons
            setButtonState(button, isPressed: isPressed)
        } else {
            #if DEBUG
                print("[NESController] Key \(keyString) not mapped to any button")
            #endif
        }
    }

    /// Loads the default key bindings (Return, Space, X, Z, arrow keys)
    private func loadDefaultKeyBindings() {
        keyBindings = [
            "start": "↩",
            "select": "␣",
            "a": "X",
            "b": "Z",
            "up": "↑",
            "down": "↓",
            "left": "←",
            "right": "→",
            "pause": "⎋",
            "screenshot": "F12",
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
            case .a: return "X"
            case .b: return "Z"
            case .select: return "␣"
            case .start: return "↩"
            case .up: return "↑"
            case .down: return "↓"
            case .left: return "←"
            case .right: return "→"
            case .pause: return "⎋"
            case .screenshot: return "F12"
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
            case .pause: return "pause"
            case .screenshot: return "screenshot"
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
            case "pause": return .pause
            case "screenshot": return .screenshot
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
            case .pause,
                 .screenshot:
                // Emulator controls are handled separately, not as controller state
                break
        }
    }

    /// Converts a macOS key code to a readable string representation.
    /// Supports all standard keyboard keys including letters, numbers, symbols, and special keys.
    /// - Parameter keyCode: The macOS key code from NSEvent
    /// - Returns: A readable string representation of the key
    private func keyStringFromCode(_ keyCode: UInt16) -> String {
        NESController.keyCodeToString(keyCode)
    }
}
