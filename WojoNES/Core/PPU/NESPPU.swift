//
//  NESPPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

class NESPPU: PPU {
    // MARK: Properties

    var bus: Bus!

    var frameBuffer: [UInt32]

    private var vram: [UInt8] = []

    private var oam: [UInt8] = []

    private var palette: [UInt8] = []

    private var scanline: Int?

    private var cycle: Int?

//    private var controlRegister: ControlRegister

    // MARK: Lifecycle

    init() {}

    // MARK: Functions

    func connect(_ bus: Bus) {
        self.bus = bus
    }

    func frameReady() -> Bool {
        <#code#>
    }

    func step() {
        <#code#>
    }

    func read(_ address: UInt16) -> UInt8 {
        <#code#>
    }

    func write(address: UInt16, value: UInt8) {
        <#code#>
    }

    private func renderScanline() {}

    private func fetchBackgrounds() {}

    private func fetchSprites() {}
}
