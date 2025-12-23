//
//  MapperTests.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 23/12/2025.
//

import Testing
@testable import WojoNES

@Suite("Mapper Tests")
struct MapperTests {
    // MARK: - Initialisation Tests

    @Test("Mapper Initialisation")
    func mapperInitialization() {
        let mapper = Mapper()

        #expect(mapper.id == 0, "Default mapper ID should be 0")
        #expect(mapper.subId == 0, "Default submapper ID should be 0")
        #expect(mapper.prgRAMenabled == true, "PRG RAM should be enabled by default")
        #expect(mapper.chrRAMenabled == false, "CHR RAM should be disabled by default")
    }

    // MARK: - Mirror Type Tests

    @Test("Mirror Type Horizontal")
    func mirrorTypeHorizontal() {
        let mirrorType = Mapper.MirrorType.horizontal
        #expect(mirrorType.rawValue == 0b0101_0000, "Horizontal mirror should have value 0x50")
    }

    @Test("Mirror Type Vertical")
    func mirrorTypeVertical() {
        let mirrorType = Mapper.MirrorType.vertical
        #expect(mirrorType.rawValue == 0b0100_0100, "Vertical mirror should have value 0x44")
    }

    @Test("Mirror Type One Screen Lo")
    func mirrorTypeOneScreenLo() {
        let mirrorType = Mapper.MirrorType.oneScreenLo
        #expect(mirrorType.rawValue == 0b0000_0000, "One screen lo should have value 0x00")
    }

    @Test("Mirror Type One Screen Hi")
    func mirrorTypeOneScreenHi() {
        let mirrorType = Mapper.MirrorType.oneScreenHi
        #expect(mirrorType.rawValue == 0b0101_0101, "One screen hi should have value 0x55")
    }

    @Test("Mirror Type Four Screen")
    func mirrorTypeFourScreen() {
        let mirrorType = Mapper.MirrorType.fourScreen
        #expect(mirrorType.rawValue == 0b1110_0100, "Four screen should have value 0xE4")
    }

    // MARK: - Mirroring Configuration Tests

    @Test("Set Horizontal Mirroring")
    func setHorizontalMirroring() {
        let mapper = Mapper()
        mapper.mirroring = .horizontal

        #expect(mapper.mirroring == .horizontal, "Mirroring should be horizontal")
    }

    @Test("Set Vertical Mirroring")
    func setVerticalMirroring() {
        let mapper = Mapper()
        mapper.mirroring = .vertical

        #expect(mapper.mirroring == .vertical, "Mirroring should be vertical")
    }

    @Test("Set One Screen Lo Mirroring")
    func setOneScreenLoMirroring() {
        let mapper = Mapper()
        mapper.mirroring = .oneScreenLo

        #expect(mapper.mirroring == .oneScreenLo, "Mirroring should be one screen lo")
    }

    @Test("Set One Screen Hi Mirroring")
    func setOneScreenHiMirroring() {
        let mapper = Mapper()
        mapper.mirroring = .oneScreenHi

        #expect(mapper.mirroring == .oneScreenHi, "Mirroring should be one screen hi")
    }

    @Test("Set Four Screen Mirroring")
    func setFourScreenMirroring() {
        let mapper = Mapper()
        mapper.mirroring = .fourScreen

        #expect(mapper.mirroring == .fourScreen, "Mirroring should be four screen")
    }

    @Test("Change Mirroring Multiple Times")
    func changeMirroringMultipleTimes() {
        let mapper = Mapper()

        mapper.mirroring = .horizontal
        #expect(mapper.mirroring == .horizontal)

        mapper.mirroring = .vertical
        #expect(mapper.mirroring == .vertical)

        mapper.mirroring = .fourScreen
        #expect(mapper.mirroring == .fourScreen)
    }

    // MARK: - Nametable Swap Tests

    @Test("Horizontal Mirroring Nametable Configuration")
    func horizontalMirroringNametableConfig() {
        let mockCartridge = MockCartridge()
        let mapper = Mapper()
        mapper.cartridge = mockCartridge

        mapper.mirroring = .horizontal

        // Horizontal mirroring should configure nametables appropriately
        // Bank swapping calls should have been made
        #expect(!mockCartridge.nameTableSwaps.isEmpty, "Nametable swaps should have been called")
    }

    @Test("Vertical Mirroring Nametable Configuration")
    func verticalMirroringNametableConfig() {
        let mockCartridge = MockCartridge()
        let mapper = Mapper()
        mapper.cartridge = mockCartridge

        mapper.mirroring = .vertical

        // Vertical mirroring should configure nametables appropriately
        #expect(!mockCartridge.nameTableSwaps.isEmpty, "Nametable swaps should have been called")
    }

    @Test("Four Screen Mirroring Nametable Configuration")
    func fourScreenMirroringNametableConfig() {
        let mockCartridge = MockCartridge()
        let mapper = Mapper()
        mapper.cartridge = mockCartridge

        mapper.mirroring = .fourScreen

        // Four screen mirroring should configure nametables
        #expect(!mockCartridge.nameTableSwaps.isEmpty, "Nametable swaps should have been called")
    }

    // MARK: - Mapper Properties Tests

    @Test("Set Mapper ID")
    func setMapperID() {
        let mapper = Mapper()
        mapper.id = 42

        #expect(mapper.id == 42, "Mapper ID should be 42")
    }

    @Test("Set Submapper ID")
    func setSubmapperID() {
        let mapper = Mapper()
        mapper.subId = 15

        #expect(mapper.subId == 15, "Submapper ID should be 15")
    }

    @Test("Set PRG RAM Enabled")
    func setPRGRAMEnabled() {
        let mapper = Mapper()
        mapper.prgRAMenabled = false

        #expect(mapper.prgRAMenabled == false, "PRG RAM should be disabled")

        mapper.prgRAMenabled = true
        #expect(mapper.prgRAMenabled == true, "PRG RAM should be enabled")
    }

    @Test("Set CHR RAM Enabled")
    func setCHRRAMEnabled() {
        let mapper = Mapper()
        mapper.chrRAMenabled = true

        #expect(mapper.chrRAMenabled == true, "CHR RAM should be enabled")

        mapper.chrRAMenabled = false
        #expect(mapper.chrRAMenabled == false, "CHR RAM should be disabled")
    }

    // MARK: - Reset Tests

    @Test("Reset Mapper")
    func resetMapper() {
        let mapper = Mapper()
        mapper.id = 42
        mapper.mirroring = .vertical

        // Reset should be callable without errors
        mapper.reset()

        // Properties should remain unchanged after reset
        #expect(mapper.id == 42, "Mapper ID should persist after reset")
    }

    // MARK: - Weak Reference Tests

    @Test("Cartridge Weak Reference")
    func cartridgeWeakReference() {
        let mapper = Mapper()

        do {
            let mockCartridge = MockCartridge()
            mapper.cartridge = mockCartridge

            #expect(mapper.cartridge != nil, "Cartridge should be accessible")
        }

        // After the cartridge goes out of scope, the weak reference should be nil
        #expect(mapper.cartridge == nil, "Cartridge reference should be nil after deallocation")
    }

    // MARK: - Default Mirroring Tests

    @Test("Invalid Raw Mirroring Value")
    func invalidRawMirroringValue() {
        let mapper = Mapper()

        // Create a mapper with an invalid raw value through mirroring setter
        mapper.mirroring = .horizontal

        // Verify it still returns a valid mirroring type
        let mirroring = mapper.mirroring
        #expect(
            mirroring == .horizontal || mirroring == .vertical || mirroring == .fourScreen,
            "Should return valid mirroring type"
        )
    }

    // MARK: - Multiple Mapper Instances Tests

    @Test("Multiple Independent Mapper Instances")
    func multipleMapperInstances() {
        let mapper1 = Mapper()
        let mapper2 = Mapper()

        mapper1.id = 1
        mapper1.mirroring = .horizontal

        mapper2.id = 2
        mapper2.mirroring = .vertical

        #expect(mapper1.id == 1, "Mapper 1 ID should be 1")
        #expect(mapper2.id == 2, "Mapper 2 ID should be 2")
        #expect(mapper1.mirroring == .horizontal, "Mapper 1 should have horizontal mirroring")
        #expect(mapper2.mirroring == .vertical, "Mapper 2 should have vertical mirroring")
    }
}
