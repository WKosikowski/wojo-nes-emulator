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

    /// The NES controller instance that tracks button states and key bindings
    private let controller: NESController

    // MARK: Lifecycle

    convenience init(cartridge: Cartridge, controller: NESController = NESController()) {
        let ppu = NESPPU(cartridge: cartridge)
        self.init(bus: NESBus(), cpu: NESCPU(), apu: NESAPU(), ppu: ppu, cartridge: cartridge, controller: controller)
    }

    init(bus: Bus, cpu: CPU, apu: APU, ppu: PPU, cartridge: Cartridge, controller: NESController = NESController()) {
        self.bus = bus
        self.cpu = cpu
        self.apu = apu
        self.ppu = ppu
        self.cartridge = cartridge
        self.controller = controller
        model = cartridge.getModel()

        // connect all components
        bus.connect(apu)
        bus.connect(ppu)
        bus.connect(cpu)
        bus.connect(cartridge)
        cpu.connect(bus)
        apu.connect(bus)
        ppu.connect(bus)

        // Set bus reference in cartridge (required for nametable mirroring)
        cartridge.bus = bus

        let nmi = Interrupt()
        let apuIrq = Interrupt()
        let dmcIrq = Interrupt()

        cpu.addNmiInterrupt(nmi)
        cpu.addApuIrqInterrupt(apuIrq)
        cpu.addDmcIrqInterrupt(dmcIrq)

        ppu.addNmiInterrupt(nmi)

        // Re-apply mirroring now that bus is connected
        // (mirroring was set during cartridge init when bus was nil)
        let currentMirroring = cartridge.mapper.mirroring
        cartridge.mapper.mirroring = currentMirroring

        // Initialize the mapper (sets up proper bank mappings)
        cartridge.mapper.reset()

        // Initialize the CPU (reads reset vector and starts execution)
        cpu.resetProgram()
    }

    // MARK: Functions

    func start() {}

    func pause() {}

    func reset() {}

    func save() {}

    func load() {}

    func mapController(_ controller: NESController) {
        bus.controller[0] = controller.toByte()
    }

    /// Sets a key binding for a specific NES controller button.
    /// Updates the internal controller's key mappings so subsequent key presses are recognised.
    /// - Parameters:
    ///   - button: The NES button to bind (e.g., .a, .b, .up, .down)
    ///   - key: The keyboard key string to bind to the button
    func setControllerKeyBinding(button: NESButton, key: String) {
        controller.setKeyBinding(button: button, key: key)
    }

    /// Retrieves the current key binding for a specific NES controller button.
    /// - Parameter button: The NES button to query
    /// - Returns: The keyboard key string bound to the button
    func getControllerKeyBinding(button: NESButton) -> String {
        controller.getKeyBinding(button: button)
    }

    func connect(cartridge: any Cartridge) {
        self.cartridge = cartridge
    }

    func step() {
        // print("step nes")
        bus.step()
    }

    func getFrame() -> PixelMatrix {
        // print("get frame")
        ppu.getFrame()
    }
}
