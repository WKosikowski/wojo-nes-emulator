//
//  KeyCaptureNSView.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 28/12/2025.
//

import SwiftUI

class KeyCaptureNSView: NSView {
    // MARK: Overridden Properties

    override var acceptsFirstResponder: Bool { true }

    // MARK: Properties

    weak var delegate: KeyCaptureView.Coordinator?

    // MARK: Overridden Functions

    override func keyDown(with event: NSEvent) {
        delegate?.keyDown(with: event)
    }

    override func becomeFirstResponder() -> Bool {
        true
    }
}
