//
//  NESEmulator.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

import Foundation

// MARK: - SaveState

/// Represents a complete save state of the NES emulator
struct SaveState: Codable {
    /// ROM data
    let romData: Data

    // CPU state
    let cpuAccumulator: UInt8
    let cpuXRegister: UInt8
    let cpuYRegister: UInt8
    let cpuStackPointer: UInt8
    let cpuProgramCounter: Int
    let cpuStatusRegisterValue: UInt8
    let cpuCycle: Int

    // Bus state
    let busRAM: Data
    let controllerState: [UInt8]

    // PPU state
    let ppuOAM: Data
    let ppuNameTableBanks: [[UInt8]]
    let ppuPaletteIndices: [Int]
    let ppuControlRegisterValue: Int
    let ppuMaskRegisterValue: Int
    let ppuStatusRegisterValue: Int
    let ppuOamAddr: UInt8
    let ppuCurrentVramAddress: Int
    let ppuNextVramAddress: Int
    let ppuCurrentVramFineX: Int
    let ppuNextVramFineX: Int
    let ppuX: Int
    let ppuY: Int
    let ppuOddFrame: Bool

    /// Cartridge save RAM
    let cartridgeWRAM: [UInt8]

    /// Controller key bindings
    let controllerKeyBindings: [String: String]
}

// MARK: - NESEmulator

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

    /// Saves the current emulator state to a file
    /// - Parameter url: The file URL to save to (should have .wnes extension)
    /// - Throws: Error if saving fails
    func save(to url: URL) throws {
        guard let nesCartridge = cartridge as? NESCartridge else {
            throw NSError(domain: "NESEmulator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid cartridge type"])
        }

        guard let nesCPU = cpu as? NESCPU else {
            throw NSError(domain: "NESEmulator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid CPU type"])
        }

        guard let nesPPU = ppu as? NESPPU else {
            throw NSError(domain: "NESEmulator", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid PPU type"])
        }

        guard let nesBus = bus as? NESBus else {
            throw NSError(domain: "NESEmulator", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid bus type"])
        }

        // Create ROM data by reconstructing the .nes file format
        let romData = try createROMData(from: nesCartridge)

        // Capture CPU state
        let saveState = SaveState(
            romData: romData,
            cpuAccumulator: nesCPU.accumulator,
            cpuXRegister: nesCPU.xRegister,
            cpuYRegister: nesCPU.yRegister,
            cpuStackPointer: nesCPU.stackPointer,
            cpuProgramCounter: nesCPU.programCounter,
            cpuStatusRegisterValue: nesCPU.statusRegister.value,
            cpuCycle: nesCPU.cycle,
            busRAM: Data(Array(nesBus.ram)),
            controllerState: nesBus.controllerState,
            ppuOAM: Data(nesPPU.oam),
            ppuNameTableBanks: nesPPU.nameTables.banks,
            ppuPaletteIndices: nesPPU.paletteIndices,
            ppuControlRegisterValue: nesPPU.controlRegister.value,
            ppuMaskRegisterValue: nesPPU.mask.value,
            ppuStatusRegisterValue: nesPPU.statusRegister.value,
            ppuOamAddr: nesPPU.oamAddr,
            ppuCurrentVramAddress: nesPPU.currentRenderingVramRegister.address,
            ppuNextVramAddress: nesPPU.nextRenderingVramRegister.address,
            ppuCurrentVramFineX: nesPPU.currentRenderingVramRegister.fineX,
            ppuNextVramFineX: nesPPU.nextRenderingVramRegister.fineX,
            ppuX: nesPPU.x,
            ppuY: nesPPU.y,
            ppuOddFrame: nesPPU.oddFrame,
            cartridgeWRAM: nesCartridge.wRam,
            controllerKeyBindings: controller.getAllKeyBindings()
        )

        // Encode and save
        let encoder = JSONEncoder()
        let data = try encoder.encode(saveState)
        try data.write(to: url)

        #if DEBUG
            print("[NESEmulator] State saved to: \(url.path)")
        #endif
    }

    /// Loads emulator state from a file
    /// - Parameter url: The file URL to load from (.wnes file)
    /// - Throws: Error if loading fails
    func load(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let saveState = try decoder.decode(SaveState.self, from: data)

        // Reload the ROM first
        let newCartridge = try NESCartridge(data: saveState.romData)

        guard let nesCPU = cpu as? NESCPU else {
            throw NSError(domain: "NESEmulator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid CPU type"])
        }

        guard let nesPPU = ppu as? NESPPU else {
            throw NSError(domain: "NESEmulator", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid PPU type"])
        }

        guard let nesBus = bus as? NESBus else {
            throw NSError(domain: "NESEmulator", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid bus type"])
        }

        // Update cartridge reference
        cartridge = newCartridge
        nesBus.connect(newCartridge)
        newCartridge.bus = nesBus

        // Update PPU's cartridge reference (critical for CHR memory access)
        nesPPU.cartridge = newCartridge

        // Restore CPU state
        nesCPU.accumulator = saveState.cpuAccumulator
        nesCPU.xRegister = saveState.cpuXRegister
        nesCPU.yRegister = saveState.cpuYRegister
        nesCPU.stackPointer = saveState.cpuStackPointer
        nesCPU.programCounter = saveState.cpuProgramCounter
        nesCPU.statusRegister.value = saveState.cpuStatusRegisterValue
        nesCPU.cycle = saveState.cpuCycle

        // Restore Bus state
        for i in 0 ..< saveState.busRAM.count {
            nesBus.ram[i] = saveState.busRAM[i]
        }
        nesBus.controllerState = saveState.controllerState

        // Restore PPU state
        for i in 0 ..< saveState.ppuOAM.count {
            nesPPU.oam[i] = saveState.ppuOAM[i]
        }
        nesPPU.nameTables.banks = saveState.ppuNameTableBanks
        nesPPU.paletteIndices = saveState.ppuPaletteIndices
        nesPPU.controlRegister.value = saveState.ppuControlRegisterValue
        nesPPU.mask.value = saveState.ppuMaskRegisterValue
        nesPPU.statusRegister.value = saveState.ppuStatusRegisterValue
        nesPPU.oamAddr = saveState.ppuOamAddr
        nesPPU.currentRenderingVramRegister.address = saveState.ppuCurrentVramAddress
        nesPPU.nextRenderingVramRegister.address = saveState.ppuNextVramAddress
        nesPPU.currentRenderingVramRegister.fineX = saveState.ppuCurrentVramFineX
        nesPPU.nextRenderingVramRegister.fineX = saveState.ppuNextVramFineX
        nesPPU.x = saveState.ppuX
        nesPPU.y = saveState.ppuY
        nesPPU.oddFrame = saveState.ppuOddFrame

        // Restore cartridge WRAM
        newCartridge.wRam = saveState.cartridgeWRAM

        // Restore controller key bindings
        controller.setAllKeyBindings(saveState.controllerKeyBindings)

        #if DEBUG
            print("[NESEmulator] State loaded from: \(url.path)")
        #endif
    }

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

    /// Creates ROM data from the current cartridge
    private func createROMData(from cartridge: NESCartridge) throws -> Data {
        var romData = Data()

        // Write header
        let headerData = cartridge.header.toData()
        romData.append(headerData)

        // Write trainer if present
        if let trainer = cartridge.trainer {
            romData.append(trainer)
        }

        // Write PRG ROM
        romData.append(cartridge.prgROM)

        // Write CHR ROM
        romData.append(cartridge.chrROM)

        return romData
    }
}
