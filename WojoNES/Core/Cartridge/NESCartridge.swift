//
//  NESCartridge.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 02/07/2025.
//
import Foundation

// MARK: - NESCartridge

/// Represents an NES cartridge, including header and ROM data
class NESCartridge: Cartridge {
    // MARK: Static Properties

    static let headerSize = 16 // NES header is 16 bytes
    static let nesIdentifier: [UInt8] = [0x4E, 0x45, 0x53, 0x1A] // "NES" + MS-DOS EOF
    static let prgUnitSize = 16 * 1024 // PRG ROM bank size: 16 KB
    static let chrUnitSize = 8 * 1024 // CHR ROM bank size: 8 KB
    static let ramUnitSize = 8 * 1024 // PRG RAM bank size: 8 KB
    static let maxPRGSize = 4096 * 1024 // Max PRG ROM size: 4096 KB
    static let maxCHRSize = 2048 * 1024 // Max CHR ROM size: 2048 KB
    static let maxRAMSize = 64 * 1024 // Max PRG RAM size: 64 KB
    static let maxMapper = 255 // Max mapper number

    // MARK: Properties

    let header: Header // Parsed header data
    let prgROM: Data // PRG ROM data
    let chrROM: Data // CHR ROM data
    let trainer: Data? // Trainer data (512 bytes, if present)
    var bus: NESBus!

    // MARK: Computed Properties

    /// Dartridge description, including header and data details - for debugging
    var description: String {
        """
        NES Cartridge:
        \(header.description)
        - PRG ROM Data: \(prgROM.count / 1024) KB
        - CHR ROM Data: \(chrROM.count / 1024) KB
        - Trainer Data: \(trainer != nil ? "\(trainer!.count) bytes" : "None")
        """
    }

    // MARK: Lifecycle

    /// Initialises the cartridge from NES file data
    init(data: Data) throws {
        // Extract and validate header
        guard data.count >= Self.headerSize else {
            throw NESCartridgeError.invalidHeaderSize
        }
        header = try Header(data: data.prefix(Self.headerSize))

        // Parse PRG ROM, CHR ROM, and trainer data

        var offset = Self.headerSize
        let trainerSize = header.hasTrainer ? 512 : 0

        // Validate data length (header + trainer + PRG + CHR)
        guard data.count >= offset + trainerSize + header.prgROMSize + header.chrRAMSize else {
            throw NESCartridgeError.invalidHeaderSize
        }

        // Extract trainer (512 bytes, if present)
        if header.hasTrainer {
            trainer = data.subdata(in: offset ..< offset + trainerSize)
            offset += trainerSize
        } else {
            trainer = nil
        }

        // Extract PRG ROM
        prgROM = data.subdata(in: offset ..< offset + header.prgROMSize)
        offset += header.prgROMSize

        // Extract CHR ROM
        chrROM = data.subdata(in: offset ..< offset + header.chrROMSize)
    }

    // MARK: Functions

    func write(data: Data, address: UInt16) {}

    func read(address: UInt16) -> UInt8 {
        1
    }

    func reset() {}
}
