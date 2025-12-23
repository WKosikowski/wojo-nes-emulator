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

    var nameTables: BankMemory = {
        var memory = BankMemory()
        // Initialize nametables (2KB VRAM with 1KB banks)
        memory.banks.append(Array(repeating: 0, count: 0x1000))
        memory.swapBanks.append(Array(repeating: 0, count: 0x1000))
        memory.bankSizeValue = 0x400
        return memory
    }()

    var connectedBus: Bus?

    // MARK: Functions

    func swapNameTable(bankIdx: Int, swapBankIdx: Int) {
        nameTables.swap(bankIdx: bankIdx, swapBankIdx: swapBankIdx)
    }

    func frameReady() -> Bool {
        false
    }

    func step() {}

    func read(_ address: UInt16) -> UInt8 {
        0
    }

    func write(address: UInt16, value: UInt8) {}

    func connect(_ bus: any Bus) { connectedBus = bus }
}
