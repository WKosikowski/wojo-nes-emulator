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

        let parent: KeyCaptureView

        // MARK: Lifecycle

        init(parent: KeyCaptureView) {
            self.parent = parent
        }

        // MARK: Functions

        func keyDown(with event: NSEvent) {
            guard parent.isCapturing, let button = parent.selectedButton else { return }
            let key = event.charactersIgnoringModifiers ?? ""
            if !key.isEmpty {
                print("[KeyCaptureView] Captured key: \(key) for button \(button.rawValue)")
                parent.viewModel.setControllerKeyBinding(button: button, key: key)
                parent.isCapturing = false
                parent.selectedButton = nil
            }
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
