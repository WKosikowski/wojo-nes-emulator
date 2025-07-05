//
//  NESEmulator.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

class NESEmulator: Emulator {
    // MARK: Properties

    let bus: Bus
    let cpu: CPU
    let apu: APU
    let ppu: PPU
    var cartridge: Cartridge

    // MARK: Lifecycle

    init(bus: Bus = NESBus(), cpu: CPU = NESCPU(), apu: APU = NESAPU(), ppu: PPU = NESPPU(), cartridge: Cartridge) {
        self.bus = bus
        self.cpu = cpu
        self.apu = apu
        self.ppu = ppu
        self.cartridge = cartridge

        // connect all components
        bus.connect(apu)
        bus.connect(ppu)
        bus.connect(cpu)
        bus.connect(cartridge)
        cpu.connect(bus)
        apu.connect(bus)
        ppu.connect(bus)
    }

    // MARK: Functions

    func start() {}

    func pause() {}

    func reset() {}

    func save() {}

    func load() {}

    func connect(cartridge: any Cartridge) {
        self.cartridge = cartridge
    }
}
