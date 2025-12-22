//
//  NESEmulatorTests.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

import Testing
@testable import WojoNES

@Suite("NESEmulator Tests")
struct NESEmulatorTests {
    @Test("Initialization sets up components correctly")
    func initialization() {
        // Arrange
        let bus = MockBus()
        let cpu = MockCPU()
        let apu = MockAPU()
        let ppu = MockPPU()

        let cartridge = MockCartridge()

        // Act
        let emulator = NESEmulator(model: .pal, bus: bus, cpu: cpu, apu: apu, ppu: ppu, cartridge: cartridge)

        // Assert
        #expect(emulator.bus === bus, "Bus should be set correctly")
        #expect(emulator.cpu === cpu, "CPU should be set correctly")
        #expect(emulator.apu === apu, "APU should be set correctly")
//        #expect(emulator.ppu is ppu, "PPU should be set correctly")
        #expect(emulator.cartridge === cartridge, "Cartridge should be set correctly")
    }

    @Test("Initialization connects components to bus")
    func componentConnectionsToBus() {
        // Arrange
        let bus = MockBus()
        let cpu = MockCPU()
        let apu = MockAPU()
        let ppu = MockPPU()
        let cartridge = MockCartridge()

        // Act
        let emulator = NESEmulator(model: .pal, bus: bus, cpu: cpu, apu: apu, ppu: ppu, cartridge: cartridge)

        // Assert
        #expect(bus.connectedComponents.count == 4, "Bus should have 4 connected components")
        #expect(bus.connectedComponents.contains { $0 as? MockAPU === apu }, "APU should be connected to bus")
        #expect(bus.connectedComponents.contains { $0 as? MockPPU === ppu }, "PPU should be connected to bus")
        #expect(bus.connectedComponents.contains { $0 as? MockCPU === cpu }, "CPU should be connected to bus")
        #expect(bus.connectedComponents.contains { $0 as? MockCartridge === cartridge }, "Cartridge should be connected to bus")
    }

    @Test("Initialization connects bus to components")
    func busConnectionsToComponents() {
        // Arrange
        let bus = MockBus()
        let cpu = MockCPU()
        let apu = MockAPU()
        let ppu = MockPPU()
        let cartridge = MockCartridge()

        // Act
        let emulator = NESEmulator(model: .pal, bus: bus, cpu: cpu, apu: apu, ppu: ppu, cartridge: cartridge)

        // Assert
        #expect(cpu.connectedBus === bus, "CPU should be connected to bus")
        #expect(apu.connectedBus === bus, "APU should be connected to bus")
        #expect(ppu.connectedBus === bus, "PPU should be connected to bus")
    }

    @Test("Connect cartridge updates cartridge property")
    func connectCartridge() {
        // Arrange
        let emulator = NESEmulator(model: .pal, cartridge: MockCartridge())
        let newCartridge = MockCartridge()

        // Act
        emulator.connect(cartridge: newCartridge)

        // Assert
        #expect(emulator.cartridge === newCartridge, "Cartridge should be updated to new cartridge")
    }

    @Test("Default initializer uses correct component types")
    func defaultInitializer() {
        // Act
        let emulator = NESEmulator(model: .pal, cartridge: MockCartridge())

        // Assert
        #expect(emulator.bus is NESBus, "Default bus should be NESBus")
        #expect(emulator.cpu is NESCPU, "Default CPU should be NESCPU")
        #expect(emulator.apu is NESAPU, "Default APU should be NESAPU")
        #expect(emulator.ppu is NESPPU, "Default PPU should be NESPPU")
    }
}
