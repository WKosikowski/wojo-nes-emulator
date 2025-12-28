

/// Represents the state of an NES controller with 8 buttons.
///
/// This structure tracks the pressed state of all NES controller buttons
/// and provides conversion to byte format for emulator input.
/// Supports dynamic key binding configuration via string-based key identifiers.
struct NESController: KeyboardMappableController {
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
    mutating func setKeyBinding(button: NESButton, key: String) {
        let buttonName = buttonName(for: button)
        keyBindings[buttonName] = key
    }

    /// Gets the current key binding for a specific NES button
    /// - Parameter button: The NES button to query
    /// - Returns: The keyboard key string, or the default if not customised
    func getKeyBinding(button: NESButton) -> String {
        let buttonName = buttonName(for: button)
        return keyBindings[buttonName] ?? getDefaultKeyBinding(for: button)
    }

    // MARK: - KeyboardMappableController

    /// Updates the controller state based on a keyboard key event.
    /// Converts the key string from the event to the appropriate button binding.
    ///
    /// - Parameters:
    ///   - keyCode: The macOS key code from NSEvent
    ///   - isPressed: Whether the key is pressed (true) or released (false)
    mutating func updateState(keyCode: UInt16, isPressed: Bool) {
        // Convert key code to string representation
        // This is a simplified approach; for production, use a proper key translation
        let keyString = keyStringFromCode(keyCode)

        // Look up which button this key is bound to
        if let button = keyCodeToButton[keyString.lowercased()] {
            setButtonState(button, isPressed: isPressed)
        }
    }

    /// Loads the default key bindings (Return, Space, X, Z, arrow keys)
    private mutating func loadDefaultKeyBindings() {
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
    private mutating func updateKeyCodeBindings() {
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
            case .a: return "x"
            case .b: return "z"
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
    private mutating func setButtonState(_ button: NESButton, isPressed: Bool) {
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

    /// Converts a macOS key code to a readable string
    /// This is a simplified mapping; extend as needed
    private func keyStringFromCode(_ keyCode: UInt16) -> String {
        switch keyCode {
            case 36: return "Return"
            case 49: return "Space"
            case 7: return "x"
            case 6: return "z"
            case 126: return "Up"
            case 125: return "Down"
            case 123: return "Left"
            case 124: return "Right"
            default: return "Unknown"
        }
    }
}
