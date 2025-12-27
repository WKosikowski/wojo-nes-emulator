

/// Represents the state of an NES controller with 8 buttons.
///
/// This structure tracks the pressed state of all NES controller buttons
/// and provides conversion to byte format for emulator input.
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

    // MARK: - KeyboardMappableController

    /// Maps macOS keyboard events to NES controller buttons.
    ///
    /// Key mapping:
    /// - Return: Start
    /// - Space: Select
    /// - X: A button
    /// - Z: B button
    /// - Arrow keys: D-pad
    ///
    /// - Parameters:
    ///   - keyCode: The macOS key code from NSEvent
    ///   - isPressed: Whether the key is pressed (true) or released (false)
    mutating func updateState(keyCode: UInt16, isPressed: Bool) {
        // Map macOS key codes to NES controller buttons
        // Key codes from: https://developer.apple.com/documentation/appkit/nsevent/1534183-keycode
        switch keyCode {
            case 36: // Return (Start)
                start = isPressed

            case 49: // Space (Select)
                select = isPressed

            case 7: // X (A button)
                a = isPressed

            case 6: // Z (B button)
                b = isPressed

            case 126: // Up Arrow
                up = isPressed

            case 125: // Down Arrow
                down = isPressed

            case 123: // Left Arrow
                left = isPressed

            case 124: // Right Arrow
                right = isPressed

            default:
                break
        }
    }
}
