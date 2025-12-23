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
    let model: NESModel

    // MARK: Lifecycle

    convenience init(model: NESModel, cartridge: Cartridge) {
        let ppu = NESPPU(cartridge: cartridge)
        self.init(model: model, bus: NESBus(), cpu: NESCPU(), apu: NESAPU(), ppu: ppu, cartridge: cartridge)
    }

    init(model: NESModel, bus: Bus, cpu: CPU, apu: APU, ppu: PPU, cartridge: Cartridge) {
        self.model = model
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
