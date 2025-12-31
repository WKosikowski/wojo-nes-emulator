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

// MARK: - EmulatorState

enum EmulatorState {
    case idle // No ROM loaded
    case running // ROM loaded and playing
    case paused // ROM loaded but paused
}

// MARK: - NESViewModel

class NESViewModel: ObservableObject {
    // MARK: Properties

    @Published var fps: Double = 0
    @Published var showFPS: Bool = false
    @Published var cpuCycles: UInt64 = 0
    @Published var scanline: Int = 0
    @Published var cycle: Int = 0
    @Published var errorMessage: String?
    @Published var pixelMap: PixelMatrix = .init(width: 256, height: 240)
    @Published var showScreenshotFeedback: Bool = false
    @Published var emulatorState: EmulatorState = .idle

    private var nes: NESEmulator?
    private let controller: NESController = .init()
    private var displayLink: CVDisplayLink?
    private var lastUpdateTime: CFTimeInterval = 0
    private var frameCount: Int = 0

    // MARK: Computed Properties

    private var screenshotDirectory: URL? {
        get {
            guard let bookmarkData = UserDefaults.standard.data(forKey: "screenshotDirectoryBookmark") else {
                return nil
            }

            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                if isStale {
                    #if DEBUG
                        print("[NESViewModel] Bookmark is stale, needs to be recreated")
                    #endif
                }

                return url
            } catch {
                #if DEBUG
                    print("[NESViewModel] Failed to resolve bookmark: \(error)")
                #endif
                return nil
            }
        }
        set {
            guard let url = newValue else {
                UserDefaults.standard.removeObject(forKey: "screenshotDirectoryBookmark")
                return
            }

            do {
                let bookmarkData = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(bookmarkData, forKey: "screenshotDirectoryBookmark")
                #if DEBUG
                    print("[NESViewModel] Saved security-scoped bookmark for: \(url.path)")
                #endif
            } catch {
                #if DEBUG
                    print("[NESViewModel] Failed to create bookmark: \(error)")
                #endif
            }
        }
    }

    // MARK: Lifecycle

    init() {
        setupDisplayLink()
        setupControllerCallbacks()
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

    func getController() -> NESController {
        controller
    }

    /// Sets a key binding for a specific NES controller button.
    /// This method updates the controller's key mappings.
    /// - Parameters:
    ///   - button: The NES button to bind (e.g., .a, .b, .up, .down)
    ///   - key: The keyboard key string to bind to the button
    func setControllerKeyBinding(button: NESButton, key: String) {
        #if DEBUG
            print("[NESViewModel] Setting binding: \(button.rawValue) -> \(key)")
        #endif
        controller.setKeyBinding(button: button, key: key)
    }

    /// Retrieves the current key binding for a specific NES controller button.
    /// - Parameter button: The NES button to query
    /// - Returns: The keyboard key string bound to the button
    func getControllerKeyBinding(button: NESButton) -> String {
        let binding = controller.getKeyBinding(button: button)
        #if DEBUG
            print("[NESViewModel] Getting binding: \(button.rawValue) -> \(binding)")
        #endif
        return binding
    }

    func resume() {
        emulatorState = .running
        #if DEBUG
            print("[NESViewModel] Resumed emulation")
        #endif
    }

    func pause() {
        emulatorState = .paused
        #if DEBUG
            print("[NESViewModel] Paused emulation")
        #endif
    }

    func reset() {
        nes?.reset()
    }

    func takeScreenshot() {
        #if DEBUG
            print("[NESViewModel] takeScreenshot() called")
            print("[NESViewModel] Screenshot directory: \(screenshotDirectory?.path ?? "nil")")
        #endif

        guard let directory = screenshotDirectory else {
            #if DEBUG
                print("[NESViewModel] Screenshot directory not set - returning early")
            #endif
            return
        }

        // Start accessing the security-scoped resource
        let accessing = directory.startAccessingSecurityScopedResource()
        #if DEBUG
            print("[NESViewModel] Security-scoped access started: \(accessing)")
        #endif

        defer {
            if accessing {
                directory.stopAccessingSecurityScopedResource()
                #if DEBUG
                    print("[NESViewModel] Security-scoped access stopped")
                #endif
            }
        }

        // Generate timestamp filename
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let filename = "screenshot_\(timestamp).png"
        let filePath = directory.appendingPathComponent(filename).path

        #if DEBUG
            print("[NESViewModel] Attempting to save screenshot to: \(filePath)")
        #endif

        // Save screenshot
        if pixelMap.saveToPNG(filePath: filePath) {
            #if DEBUG
                print("[NESViewModel] Screenshot saved successfully!")
            #endif

            // Show camera icon feedback
            showScreenshotFeedback = true

            // Hide feedback after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.showScreenshotFeedback = false
            }
        } else {
            #if DEBUG
                print("[NESViewModel] Failed to save screenshot")
            #endif
        }
    }

    func selectScreenshotDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true
        openPanel.title = "Select Screenshot Directory"
        openPanel.prompt = "Select"

        openPanel.begin { [weak self] result in
            guard let self else { return }
            if result == .OK, let url = openPanel.url {
                screenshotDirectory = url
                #if DEBUG
                    print("[NESViewModel] Screenshot directory set to: \(url.path)")
                #endif
            }
        }
    }

    func getScreenshotDirectory() -> String? {
        screenshotDirectory?.path
    }

    func loadROM() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [
            .init(filenameExtension: "nes")!,
            .init(filenameExtension: "wnes")!,
        ]
        openPanel.title = "Select NES ROM or Save State"

        openPanel.begin { [weak self] result in
            guard let self else { return }

            if result == .OK, let url = openPanel.url {
                do {
                    // Check file extension to determine if it's a save state or ROM
                    if url.pathExtension.lowercased() == "wnes" {
                        // Load save state
                        if let nesEmulator = nes as? NESEmulator {
                            try nesEmulator.load(from: url)
                            errorMessage = nil
                            #if DEBUG
                                print("[NESViewModel] Save state loaded successfully")
                            #endif
                        } else {
                            // No existing emulator - need to create one from the save state
                            // First decode the save state to get the ROM data
                            let saveStateData = try Data(contentsOf: url)
                            let decoder = JSONDecoder()
                            let saveState = try decoder.decode(SaveState.self, from: saveStateData)

                            // Create cartridge from the embedded ROM data
                            let tempCartridge = try NESCartridge(data: saveState.romData)
                            let nesEmulator = NESEmulator(cartridge: tempCartridge, controller: controller)

                            // Now load the full state
                            try nesEmulator.load(from: url)
                            nes = nesEmulator
                            errorMessage = nil
                            #if DEBUG
                                print("[NESViewModel] Save state loaded (new emulator)")
                            #endif
                        }
                    } else {
                        // Load ROM
                        let cartridge = try NESCartridge(data: Data(contentsOf: url))
                        nes = NESEmulator(cartridge: cartridge, controller: controller)
                        errorMessage = nil
                    }

                    // Start the emulator automatically when ROM/state is loaded
                    emulatorState = .running
                } catch {
                    errorMessage = "Failed to load file: \(error.localizedDescription)"
                }
            }
        }
    }

    func saveState() {
        #if DEBUG
            print("[NESViewModel] saveState() called")
        #endif

        guard let nesEmulator = nes as? NESEmulator else {
            #if DEBUG
                print("[NESViewModel] No emulator instance available")
            #endif
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "wnes")!]
        savePanel.canCreateDirectories = true
        savePanel.title = "Save Emulator State"
        savePanel.nameFieldStringValue = "save_state.wnes"

        savePanel.begin { [weak self] result in
            guard let self else { return }

            if result == .OK, let url = savePanel.url {
                do {
                    try nesEmulator.save(to: url)
                    #if DEBUG
                        print("[NESViewModel] State saved successfully to: \(url.path)")
                    #endif
                } catch {
                    errorMessage = "Failed to save state: \(error.localizedDescription)"
                    #if DEBUG
                        print("[NESViewModel] Failed to save state: \(error)")
                    #endif
                }
            }
        }
    }

    private func setupControllerCallbacks() {
        #if DEBUG
            print("[NESViewModel] Setting up controller callbacks")
        #endif

        controller.onScreenshotPressed = { [weak self] in
            #if DEBUG
                print("[NESViewModel] Screenshot callback triggered!")
            #endif
            self?.takeScreenshot()
        }

        controller.onPauseToggled = { [weak self] in
            #if DEBUG
                print("[NESViewModel] Pause callback triggered!")
            #endif
            guard let self else { return }
            if emulatorState == .running {
                pause()
            } else if emulatorState != .idle {
                resume()
            }
        }
    }

    private func setupDisplayLink() {
        #if DEBUG
            print("[NESViewModel] Setting up display link")
        #endif
        let displayID = CGMainDisplayID()
        var displayLink: CVDisplayLink?

        CVDisplayLinkCreateWithCGDisplay(displayID, &displayLink)
        self.displayLink = displayLink

        guard let displayLink else { return }

        CVDisplayLinkSetOutputCallback(displayLink, { _, _, _, _, _, displayLinkContext -> CVReturn in
            let viewModel = unsafeBitCast(displayLinkContext, to: NESViewModel.self)
            viewModel.update()
            return kCVReturnSuccess
        }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))

        CVDisplayLinkSetCurrentCGDisplay(displayLink, displayID)

        // Start the display link immediately - it runs continuously
        // Pausing is handled by checking the emulator state, not by stopping the link
        CVDisplayLinkStart(displayLink)
    }

    private func update() {
        guard let nes, emulatorState == .running else { return }

        nes.step()
        let frame = nes.getFrame()

        let currentTime = CACurrentMediaTime()
        frameCount += 1

        let shouldUpdateFPS = currentTime - lastUpdateTime >= 1.0
        let currentFPS = shouldUpdateFPS ? Double(frameCount) : nil

        // Update @Published properties on the main thread to avoid menu modification crash
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            pixelMap = frame

            if let currentFPS {
                fps = currentFPS
                frameCount = 0
                lastUpdateTime = currentTime
            }
        }
    }
}
