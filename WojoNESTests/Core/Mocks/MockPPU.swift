//
//  MockPPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//
@testable import WojoNES

class MockPPU: PPU {
    // MARK: Properties

    var frameBuffer: [UInt32] = []

    var frame: PixelMatrix = .init(width: 256, height: 240)

    var nameTables: BankMemory = {
        var memory = BankMemory()
        // Initialise nametables (2KB VRAM with 1KB banks)
        memory.banks.append(Array(repeating: 0, count: 0x1000))
        memory.swapBanks.append(Array(repeating: 0, count: 0x1000))
        memory.bankSizeValue = 0x400
        return memory
    }()

    var connectedBus: Bus?

    var frameComplete: Bool = false

    // MARK: Functions

    func swapNameTable(bankIdx: Int, swapBankIdx: Int) {
        nameTables.swap(bankIdx: bankIdx, swapBankIdx: swapBankIdx)
    }

    func step() {}

    func read(_ address: Int) -> UInt8 {
        0
    }

    func write(address: Int, value: UInt8) {}

    func connect(_ bus: any Bus) { connectedBus = bus }

    func getFrame() -> PixelMatrix {
        frame
    }
}
