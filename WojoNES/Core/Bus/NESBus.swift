//
//  NESBus.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

class NESBus: Bus {
    // MARK: Properties

    var memory: [UInt8] = Array(repeating: 0, count: 0x10000)
    var ppu: PPU!
    var apu: APU!
    var cpu: CPU!
    var cartridge: Cartridge!

    // MARK: Lifecycle

    init() {}

    // MARK: Functions

    func read(address: Int) -> UInt8 {
        memory[address]
    }

    func write(address: Int, data: UInt8) {
        memory[address] = data
    }

    func connect(_ ppu: PPU) {
        self.ppu = ppu
    }

    func connect(_ apu: APU) {
        self.apu = apu
    }

    func connect(_ cartridge: any Cartridge) {
        self.cartridge = cartridge
    }

    func connect(_ cpu: CPU) {
        self.cpu = cpu
    }
}
