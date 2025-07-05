//
//  NESBus.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

class NESBus: Bus {
    // MARK: Properties

    var ram: [UInt8] = Array(repeating: 0, count: 0x10000)
    var ppu: PPU!
    var apu: APU!
    var cpu: CPU!
    var cartridge: Cartridge!

    // MARK: Lifecycle

    init() {}

    // MARK: Functions

    func read(address: Int) -> UInt8 {
        switch address {
            case 0 ..< 0x2000:
                return ram[address & 0x7FF]
            case 0x8000...:
                return cartridge.read(address: address & 0x1FFF)
            default:
                assertionFailure("Not implemented")
                return 0
        }
    }

    func write(address: Int, data: UInt8) {
        // todo implement
        ram[address] = data
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
