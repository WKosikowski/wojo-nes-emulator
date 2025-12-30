

import MetalKit
import SwiftUI

// MARK: - KeyboardMappableController

/// Protocol that controller types must conform to for keyboard-based input mapping.
///
/// Implement this protocol on your controller type to enable keyboard input handling.
protocol KeyboardMappableController {
    /// Creates a default controller state
    init()

    /// Updates the controller state based on a keyboard event
    /// - Parameters:
    ///   - keyCode: The key code from the keyboard event
    ///   - isPressed: Whether the key was pressed (true) or released (false)
    mutating func updateState(keyCode: UInt16, isPressed: Bool)
}

// MARK: - KeyboardPressDetectionMetalView

/// A Metal view that detects keyboard input and maps it to a generic controller type.
///
/// This view captures keyboard events and translates them into controller state updates,
/// making it suitable for emulator input handling.
///
/// - Note: The controller type must conform to `KeyboardMappableController`.
class KeyboardPressDetectionMetalView<Controller: KeyboardMappableController>: MTKView {
    // MARK: Overridden Properties

    override var acceptsFirstResponder: Bool { true }

    // MARK: Properties

    var controllerState: Controller?
    var onControllerUpdate: ((Controller) -> Void)?

    // MARK: Overridden Functions

    override func keyDown(with event: NSEvent) {
        guard let controller = controllerState else { return }
        var mutableController = controller
        mutableController.updateState(keyCode: event.keyCode, isPressed: true)
        onControllerUpdate?(mutableController)
    }

    override func keyUp(with event: NSEvent) {
        guard let controller = controllerState else { return }
        var mutableController = controller
        mutableController.updateState(keyCode: event.keyCode, isPressed: false)
        onControllerUpdate?(mutableController)
    }
}
