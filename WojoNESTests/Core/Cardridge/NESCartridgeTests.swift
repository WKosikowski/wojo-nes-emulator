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

        // Initialize the cartridge
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
}

// MARK: - TestError

/// Helper error for test setup issues
struct TestError: Error {
    // MARK: Properties

    let message: String

    // MARK: Lifecycle

    init(_ message: String) { self.message = message }
}
