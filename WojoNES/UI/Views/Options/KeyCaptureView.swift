//
//  KeyCaptureView.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 28/12/2025.
//

import AppKit
import SwiftUI

struct KeyCaptureView: NSViewRepresentable {
    // MARK: Nested Types

    class Coordinator: NSObject {
        // MARK: Properties

        var parent: KeyCaptureView
        var viewModel: NESViewModel?

        // MARK: Lifecycle

        init(parent: KeyCaptureView) {
            self.parent = parent
        }

        // MARK: Functions

        func keyDown(with event: NSEvent) {
            guard parent.isCapturing, let button = parent.selectedButton else { return }
            // Use keyCode to get a readable string for all keys including special keys
            let key = NESController.keyCodeToString(event.keyCode)
            print("[KeyCaptureView] Captured key: \(key) (keyCode: \(event.keyCode)) for button \(button.rawValue)")
            viewModel?.setControllerKeyBinding(button: button, key: key)
            parent.isCapturing = false
            parent.selectedButton = nil
        }
    }

    // MARK: SwiftUI Properties

    @Binding var isCapturing: Bool
    @Binding var selectedButton: NESButton?
    @EnvironmentObject var viewModel: NESViewModel

    // MARK: Functions

    func makeNSView(context: Context) -> KeyCaptureNSView {
        let view = KeyCaptureNSView()
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) {
        // Update coordinator's references to current parent and viewModel
        context.coordinator.parent = self
        context.coordinator.viewModel = viewModel

        // Set first responder when capturing starts
        if isCapturing {
            DispatchQueue.main.async {
                if nsView.window?.firstResponder != nsView {
                    let success = nsView.window?.makeFirstResponder(nsView)
                    print("Make first responder: \(success ?? false)")
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}
