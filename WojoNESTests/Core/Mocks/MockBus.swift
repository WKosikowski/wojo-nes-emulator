//
//  MockBus.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//
@testable import WojoNES

/// Mock implementations for dependencies
class MockBus: Bus {
    // MARK: Properties

    var controller: [UInt8] = .init(repeating: 0, count: 2)

    var connectedComponents: [Any] = []

    var ram: [Int: UInt8] = [:]

    var ppu: PPU! = MockPPU()

    var cpu = MockCPU()

    var apu: APU! = MockAPU()

    var dmaOamAddr: Int = 0

    // MARK: Computed Properties

    var cycle: Int {
        cpu.cycle
    }

    // MARK: Functions

    func read(address: Int) -> UInt8 {
        ram[address] ?? 0
    }

    func write(address: Int, data: UInt8) {
        ram[address] = data
    }

    func connect(_ component: any APU) { connectedComponents.append(component) }
    func connect(_ component: any PPU) { connectedComponents.append(component) }
    func connect(_ component: any CPU) { connectedComponents.append(component) }
    func connect(_ component: any Cartridge) { connectedComponents.append(component) }

    func swapNameTable(bankIdx: Int, swapBankIdx: Int) {
        ppu.swapNameTable(bankIdx: bankIdx, swapBankIdx: swapBankIdx)
    }

    func step() {}

    func resetCycles() {
        cpu.resetCycles()
    }
}
