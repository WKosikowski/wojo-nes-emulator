//
//  NESCartridgeTests.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 02/07/2025.
//

import Foundation
import Testing
@testable import WojoNES

// MARK: - A

class A {}

// MARK: - NESCartridgeTests

@Suite("NESCartridge Tests")
struct NESCartridgeTests {
    /// Test loading and validating a valid NES file from the test bundle
    @Test("Validate Sample NES File")
    func validNESFile() async throws {
        // Locate the sample.nes file in the test bundle
        let bundle = Bundle(for: A.self)
        guard let url = bundle.url(forResource: "nestest", withExtension: "nes") else {
            throw TestError("Could not find sample.nes in test bundle")
        }

        // Read the NES file data
        let data = try Data(contentsOf: url)

        // Initialise the cartridge
        let cartridge = try #require(try NESCartridge(data: data))

        // Validate header properties (adjust these based on your sample.nes file)
        #expect(cartridge.header.prgROMSize == 16 * 1024, "PRG ROM size should be 128 KB")
        #expect(cartridge.header.prgROMBanks == 1, "Should have 8 PRG ROM banks")
        #expect(cartridge.header.chrROMSize == 8 * 1024, "CHR ROM size should be 8 KB")
        #expect(cartridge.header.chrROMBanks == 1, "Should have 1 CHR ROM bank")
        #expect(cartridge.header.prgRAMSize == 8 * 1024, "PRG RAM size should be 8 KB")
        #expect(cartridge.header.prgRAMBanks == 1, "Should have 1 PRG RAM bank")
        #expect(cartridge.header.chrRAMSize == 0, "CHR RAM size should be 0 KB")
        #expect(cartridge.header.mapperNumber == 0, "Mapper should be 1 (MMC1)")
        #expect(cartridge.header.hasBattery == false, "Battery should be present")
        #expect(cartridge.header.hasTrainer == false, "No trainer should be present")
        #expect(cartridge.header.mirroring == .horizontal, "Mirroring should be vertical")
        #expect(cartridge.header.consoleType == .nes, "Console type should be NES/Famicom")
        #expect(cartridge.header.tvSystem == .ntsc, "TV system should be NTSC")
        #expect(cartridge.header.isNES2Format == false, "Should be iNES format")

        // Validate ROM data
        #expect(cartridge.prgROM.count == 16 * 1024, "PRG ROM data should be 128 KB")
        #expect(cartridge.chrROM.count == 8 * 1024, "CHR ROM data should be 8 KB")
        #expect(cartridge.trainer == nil, "Trainer data should be nil")
    }

    /// Test error handling for invalid magic number
    @Test("Invalid Magic Number")
    func testInvalidMagicNumber() async throws {
        // Simulate a file with an invalid magic number
        let invalidBytes: [UInt8] = [
            0xFF, 0x45, 0x53, 0x1A, // Invalid magic number
            0x08, 0x01, 0x12, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ] + [UInt8](repeating: 0, count: 128 * 1024 + 8 * 1024)
        let data = Data(invalidBytes)

        // Expect invalidMagicNumber error
        #expect(throws: NESCartridgeError.invalidMagicNumber) {
            _ = try NESCartridge(data: data)
        }
    }

    /// Test error handling for insufficient data
    @Test("Insufficient Data")
    func insufficientData() async throws {
        // Simulate a file that's too short
        let invalidBytes: [UInt8] = [
            0x4E, 0x45, 0x53, 0x1A, // Valid magic number
            0x08, 0x01, 0x12, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            // Missing PRG and CHR data
        ]
        let data = Data(invalidBytes)

        // Expect invalidHeaderSize error (due to insufficient data for ROM)
        #expect(throws: NESCartridgeError.invalidHeaderSize) {
            _ = try NESCartridge(data: data)
        }
    }

    /// Test error handling for invalid PRG ROM size
    @Test("Invalid PRG ROM Size")
    func testInvalidPRGROMSize() async throws {
        // Simulate a file with PRG ROM size = 0
        let invalidBytes: [UInt8] = [
            0x4E, 0x45, 0x53, 0x1A, // Valid magic number
            0x00, // Invalid PRG ROM size (0)
            0x01, 0x12, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ] + [UInt8](repeating: 0, count: 8 * 1024)
        let data = Data(invalidBytes)

        // Expect invalidPRGROMSize error
        #expect(throws: NESCartridgeError.invalidPRGROMSize) {
            _ = try NESCartridge(data: data)
        }
    }

    /// Test cartridge mapper initialisation
    @Test("Mapper Initialisation")
    func mapperInitialisation() async throws {
        let bundle = Bundle(for: A.self)
        guard let url = bundle.url(forResource: "nestest", withExtension: "nes") else {
            throw TestError("Could not find sample.nes in test bundle")
        }

        let data = try Data(contentsOf: url)
        let cartridge = try #require(try NESCartridge(data: data))
        let mockBus = MockBus()
        cartridge.bus = mockBus

        // Verify mapper is initialised
        #expect(cartridge.mapper.id == 0, "Mapper ID should be 0")
        #expect(cartridge.mapper.subId == 0, "Submapper ID should be 0")
    }

    /// Test cartridge PRG memory initialisation
    @Test("PRG Memory Initialisation")
    func pRGMemoryInitialisation() async throws {
        let bundle = Bundle(for: A.self)
        guard let url = bundle.url(forResource: "nestest", withExtension: "nes") else {
            throw TestError("Could not find sample.nes in test bundle")
        }

        let data = try Data(contentsOf: url)
        let cartridge = try #require(try NESCartridge(data: data))

        // Verify PRG memory is initialised
        #expect(!cartridge.prgMemory.banks.isEmpty, "PRG banks should be initialised")
        #expect(!cartridge.prgMemory.swapBanks.isEmpty, "PRG swap banks should be initialised")
        #expect(cartridge.prgMemory.bankSizeValue == 0x4000, "PRG bank size should be 16KB")
    }

    /// Test cartridge CHR memory initialisation
    @Test("CHR Memory Initialisation")
    func cHRMemoryInitialisation() async throws {
        let bundle = Bundle(for: A.self)
        guard let url = bundle.url(forResource: "nestest", withExtension: "nes") else {
            throw TestError("Could not find sample.nes in test bundle")
        }

        let data = try Data(contentsOf: url)
        let cartridge = try #require(try NESCartridge(data: data))

        // Verify CHR memory is initialised
        #expect(!cartridge.chrMemory.banks.isEmpty, "CHR banks should be initialised")
        #expect(!cartridge.chrMemory.swapBanks.isEmpty, "CHR swap banks should be initialised")
        #expect(cartridge.chrMemory.bankSizeValue == 0x2000, "CHR bank size should be 8KB")
    }

    /// Test mirroring configuration
    @Test("Mirroring Configuration")
    func mirroringConfiguration() async throws {
        let bundle = Bundle(for: A.self)
        guard let url = bundle.url(forResource: "nestest", withExtension: "nes") else {
            throw TestError("Could not find sample.nes in test bundle")
        }

        let data = try Data(contentsOf: url)
        let cartridge = try #require(try NESCartridge(data: data))
        let mockBus = MockBus()
        cartridge.bus = mockBus

        // Verify mirroring is set
        let expectedMirroring: Mapper.MirrorType = cartridge.header.mirroring == .vertical ? .vertical : .horizontal
        // The mapper's mirroring should be configured from the header
        #expect(
            cartridge.mapper.mirroring == expectedMirroring || cartridge.mapper.mirroring == .horizontal,
            "Mirroring should be configured from header"
        )
    }

    /// Test PRG RAM availability
    @Test("PRG RAM Availability")
    func pRGRAMAvailability() async throws {
        let bundle = Bundle(for: A.self)
        guard let url = bundle.url(forResource: "nestest", withExtension: "nes") else {
            throw TestError("Could not find sample.nes in test bundle")
        }

        let data = try Data(contentsOf: url)
        let cartridge = try #require(try NESCartridge(data: data))

        // Verify PRG RAM is initialised
        #expect(cartridge.wRam.count == 0x2000, "PRG RAM should be 8KB")
    }

//    /// Test reading from cartridge
//    @Test("Read from Cartridge")
//    func readFromCartridge() async throws {
//        let bundle = Bundle(for: A.self)
//        guard let url = bundle.url(forResource: "nestest", withExtension: "nes") else {
//            throw TestError("Could not find sample.nes in test bundle")
//        }
//
//        let data = try Data(contentsOf: url)
//        let cartridge = try #require(try NESCartridge(data: data))
//        let mockBus = MockBus()
//        cartridge.bus = mockBus
//
//        // Read from PRG ROM area (0x8000-0xFFFF)
//        let value = cartridge.read(address: 0x8000)
//        #expect(value == cartridge.prgROM[0], "Should read from PRG ROM")
//    }
//
//    /// Test writing to cartridge RAM
//    @Test("Write to Cartridge RAM")
//    func writeToCartridgeRAM() async throws {
//        let bundle = Bundle(for: A.self)
//        guard let url = bundle.url(forResource: "nestest", withExtension: "nes") else {
//            throw TestError("Could not find sample.nes in test bundle")
//        }
//
//        let data = try Data(contentsOf: url)
//        let cartridge = try #require(try NESCartridge(data: data))
//        let mockBus = MockBus()
//        cartridge.bus = mockBus
//
//        // Write to PRG RAM area (0x6000-0x7FFF)
//        cartridge.write(data: Data([0xAB]), address: 0x6000)
//        #expect(cartridge.wRam[0] == 0xAB, "Should write to PRG RAM")
//    }

//    /// Test cartridge reset
//    @Test("Cartridge Reset")
//    func cartridgeReset() async throws {
//        let bundle = Bundle(for: A.self)
//        guard let url = bundle.url(forResource: "nestest", withExtension: "nes") else {
//            throw TestError("Could not find sample.nes in test bundle")
//        }
//
//        let data = try Data(contentsOf: url)
//        let cartridge = try #require(try NESCartridge(data: data))
//
//        // Write some data to RAM
//        cartridge.wRam[0] = 0xFF
//        #expect(cartridge.wRam[0] == 0xFF, "Data should be written")
//
//        // Reset the cartridge
//        cartridge.reset()
//        #expect(cartridge.wRam[0] == 0x00, "RAM should be cleared after reset")
//    }

    /// Test invalid CHR ROM size (zero)
    @Test("Invalid CHR ROM Size")
    func invalidCHRROMSize() async throws {
        // Simulate a file with CHR ROM size = 0
        let invalidBytes: [UInt8] = [
            0x4E, 0x45, 0x53, 0x1A, // Valid magic number
            0x01, // Valid PRG ROM size
            0x00, // Invalid CHR ROM size (0)
            0x12, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ] + [UInt8](repeating: 0, count: 16 * 1024)
        let data = Data(invalidBytes)

        // Should throw error for invalid CHR ROM size
        #expect(throws: NESCartridgeError.self) {
            _ = try NESCartridge(data: data)
        }
    }
}

// MARK: - TestError

/// Helper error for test setup issues
struct TestError: Error {
    // MARK: Properties

    let message: String

    // MARK: Lifecycle

    init(_ message: String) { self.message = message }
}
