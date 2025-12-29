//
//  NESViewModel.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 23/12/2025.
//

import CoreVideo
import Foundation
import MetalKit
import SwiftUI

class NESViewModel: ObservableObject {
    // MARK: Properties

    @Published var fps: Double = 0
    @Published var showFPS: Bool = false
    @Published var cpuCycles: UInt64 = 0
    @Published var scanline: Int = 0
    @Published var cycle: Int = 0
    @Published var errorMessage: String?
    @Published var pixelMap: PixelMatrix = .init(width: 256, height: 240)

    private var nes: NESEmulator?
    private let controller: NESController = .init()
    private var displayLink: CVDisplayLink?
    private var lastUpdateTime: CFTimeInterval = 0
    private var frameCount: Int = 0

    // MARK: Lifecycle

    init() {
        setupDisplayLink()
    }

    deinit {
        if let displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }

    // MARK: Functions

    func nesControllerEvent(controller: NESController) {
        nes?.mapController(controller)
    }

    /// Sets a key binding for a specific NES controller button.
    /// This method updates the controller's key mappings.
    /// - Parameters:
    ///   - button: The NES button to bind (e.g., .a, .b, .up, .down)
    ///   - key: The keyboard key string to bind to the button
    func setControllerKeyBinding(button: NESButton, key: String) {
        print("[NESViewModel] Setting binding: \(button.rawValue) -> \(key)")
        controller.setKeyBinding(button: button, key: key)
    }

    /// Retrieves the current key binding for a specific NES controller button.
    /// - Parameter button: The NES button to query
    /// - Returns: The keyboard key string bound to the button
    func getControllerKeyBinding(button: NESButton) -> String {
        let binding = controller.getKeyBinding(button: button)
        print("[NESViewModel] Getting binding: \(button.rawValue) -> \(binding)")
        return binding
    }

    func resume() {
        guard let displayLink else { return }
        print("resume")
        CVDisplayLinkStart(displayLink)
    }

    func pause() {
        guard let displayLink else { return }
        CVDisplayLinkStop(displayLink)
    }

    func reset() {
        nes?.reset()
    }

    func loadROM() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.init(filenameExtension: "nes")!]
        openPanel.title = "Select NES ROM"

        openPanel.begin { [weak self] result in
            guard let self else { return }

            if result == .OK, let url = openPanel.url {
                do {
                    let cartridge = try NESCartridge(data: Data(contentsOf: url))
                    nes = NESEmulator(cartridge: cartridge, controller: controller)

                    errorMessage = nil
                } catch {
                    errorMessage = "Failed to load ROM: \(error.localizedDescription)"
                }
            }
        }
    }

    private func setupDisplayLink() {
        print("setup")
        let displayID = CGMainDisplayID()
        var displayLink: CVDisplayLink?

        CVDisplayLinkCreateWithCGDisplay(displayID, &displayLink)
        self.displayLink = displayLink

        guard let displayLink else { return }

        CVDisplayLinkSetOutputCallback(displayLink, { _, _, _, _, _, displayLinkContext -> CVReturn in
            let viewModel = unsafeBitCast(displayLinkContext, to: NESViewModel.self)
            viewModel.update()
            print("update")
            return kCVReturnSuccess
        }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))

        CVDisplayLinkSetCurrentCGDisplay(displayLink, displayID)
    }

    private func update() {
        guard let nes else { return }
        print(nes)
        nes.step()

        pixelMap = nes.getFrame()

        let currentTime = CACurrentMediaTime()
        frameCount += 1

        if currentTime - lastUpdateTime >= 1.0 {
            fps = Double(frameCount)
            frameCount = 0
            lastUpdateTime = currentTime
        }
    }
}

#Preview {
    NESView()
}
