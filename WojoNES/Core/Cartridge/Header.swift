//
//  Header.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 02/07/2025.
//

import Foundation

/// Parses and validates the 16-byte NES header (iNES or NES 2.0 format)
struct Header {
    // MARK: Nested Types

    /// Mirroring types for PPU nametable arrangement
    enum Mirroring: String {
        case horizontal = "Horizontal"
        case vertical = "Vertical"
    }

    // MARK: Properties

    /// Raw header bytes
    let bytes: Data

    // MARK: Computed Properties

    /// PRG ROM size in bytes (iNES: byte 4 * 16 KB; NES 2.0: byte 9 for extended sizes)
    var prgROMSize: Int {
        if isNES2Format, (bytes[9] & 0x0F) == 0x0F {
            let exponent = Int(bytes[4] & 0xFC) >> 2
            let multiplier = Int(bytes[4] & 0x03)
            return (1 << exponent) * (multiplier * 2 + 1)
        }
        return Int(bytes[4]) * NESCartridge.prgUnitSize
    }

    /// CHR ROM size in bytes (iNES: byte 5 * 8 KB; NES 2.0: byte 9 for extended sizes)
    var chrROMSize: Int {
        if isNES2Format, (bytes[9] & 0xF0) == 0xF0 {
            let exponent = Int(bytes[5] & 0xFC) >> 2
            let multiplier = Int(bytes[5] & 0x03)
            return (1 << exponent) * (multiplier * 2 + 1)
        }
        return Int(bytes[5]) * NESCartridge.chrUnitSize
    }

    /// PRG RAM size in bytes (iNES: byte 8; NES 2.0: byte 10; defaults to 8 KB if 0)
    var prgRAMSize: Int {
        let rawSize = isNES2Format ? Int(bytes[10]) : Int(bytes[8])
        return rawSize == 0 ? NESCartridge.ramUnitSize : rawSize * NESCartridge.ramUnitSize
    }

    /// CHR RAM size in bytes (8 KB if CHR ROM is absent, else 0)
    var chrRAMSize: Int {
        chrROMSize == 0 ? NESCartridge.chrUnitSize : 0
    }

    /// Number of PRG ROM banks (16 KB each)
    var prgROMBanks: Int {
        prgROMSize / NESCartridge.prgUnitSize
    }

    /// Number of CHR ROM banks (8 KB each)
    var chrROMBanks: Int {
        chrROMSize / NESCartridge.chrUnitSize
    }

    /// Number of PRG RAM banks (8 KB each)
    var prgRAMBanks: Int {
        prgRAMSize / NESCartridge.ramUnitSize
    }

    /// Mapper number (lower 4 bits from byte 6, upper 4 bits from byte 7)
    var mapperNumber: Int {
        let mapperLow = Int(bytes[6] >> 4)
        let mapperHigh = Int(bytes[7] & 0xF0)
        return mapperLow | mapperHigh
    }

    /// Submapper number (NES 2.0: upper 4 bits of byte 11)
    var submapperNumber: Int {
        isNES2Format ? Int(bytes[11] >> 4) : 0
    }

    /// Mirroring type (byte 6, bit 0)
    var mirroring: Mirroring {
        (bytes[6] & 0x01 == 0) ? .horizontal : .vertical
    }

    /// Battery-backed RAM presence (byte 6, bit 1)
    var hasBattery: Bool {
        (bytes[6] & 0x02) != 0
    }

    /// Trainer presence (byte 6, bit 2; 512-byte trainer before PRG ROM)
    var hasTrainer: Bool {
        (bytes[6] & 0x04) != 0
    }

    /// Four-screen VRAM (ignores mirroring control; byte 6, bit 3)
    var ignoreMirrorControl: Bool {
        (bytes[6] & 0x08) != 0
    }

    /// NES 2.0 format detection (byte 7, bits 3-2 = 0b10)
    var isNES2Format: Bool {
        (bytes[7] & 0x0C) == 0x08
    }

    /// Console type (byte 7, bits 0-1; extended for NES 2.0)
    var consoleType: ConsoleType {
        let flags7 = bytes[7]
        if flags7 & 0x01 != 0 {
            return .vsSystem
        }
        if flags7 & 0x02 != 0 {
            return .playchoice
        }
        return isNES2Format ? .extended : .nes
    }

    /// TV system (iNES: byte 9; NES 2.0: byte 12)
    var tvSystem: TVSystem {
        let tvByte = isNES2Format ? bytes[12] : bytes[9]
        switch tvByte & 0x03 {
            case 0: return .ntsc
            case 1: return .pal
            case 2: return .dual
            default: return .ntsc
        }
    }

    // MARK: - Description

    /// Human-readable header description with all parsed fields
    var description: String {
        """
        NES Header:
        - NES Format: \(isNES2Format ? "NES 2.0" : "iNES")
        - PRG ROM Size: \(prgROMSize / 1024) KB (\(prgROMBanks) banks)
        - CHR ROM Size: \(chrROMSize / 1024) KB (\(chrROMBanks) banks)
        - PRG RAM Size: \(prgRAMSize / 1024) KB (\(prgRAMBanks) banks)
        - CHR RAM size: \(chrRAMSize / 1024) KB
        - Mapper: \(mapperNumber) (Submapper: \(submapperNumber))
        - Mirroring: \(mirroring.rawValue)
        - Battery-backed RAM: \(hasBattery ? "Present" : "Not Present")
        - Trainer: \(hasTrainer)
        - Ignore Mirror control: \(ignoreMirrorControl)
        - Console: \(consoleType.rawValue)
        - TV standard: \(tvSystem.rawValue)
        """
    }

    // MARK: Lifecycle

    // MARK: - Initialisation

    /// Initialises and validates the 16-byte header
    init(data: Data) throws {
        // Validate header size
        guard data.count == NESCartridge.headerSize else {
            throw NESCartridgeError.invalidHeaderSize
        }
        // Validate magic number ("NES" + EOF)
        guard Array(data.prefix(4)) == NESCartridge.nesIdentifier else {
            throw NESCartridgeError.invalidMagicNumber
        }
        bytes = data

        // Validate PRG ROM size (must be positive and within limits)
        guard prgROMSize > 0, prgROMSize <= NESCartridge.maxPRGSize else {
            throw NESCartridgeError.invalidPRGROMSize
        }

        // Validate CHR ROM size (can be 0 for CHR RAM, within limits)
        guard chrROMSize >= 0, chrROMSize <= NESCartridge.maxCHRSize else {
            throw NESCartridgeError.invalidCHRROMSize
        }

        // Validate PRG RAM size (within reasonable limits)
        guard prgRAMSize >= 0, prgRAMSize <= NESCartridge.maxRAMSize else {
            throw NESCartridgeError.invalidPRGRAMSize
        }

        // Validate mapper number (0-255)
        guard mapperNumber >= 0, mapperNumber <= NESCartridge.maxMapper else {
            throw NESCartridgeError.unsupportedMapper
        }

        // Validate flags (bytes 6-9) for console type and format
        guard validateFlags(bytes[6], bytes[7], bytes[8], bytes[9]) else {
            throw NESCartridgeError.invalidHeaderFlags
        }

        // Validate reserved bytes (10-15 zero for iNES, any for NES 2.0)
        guard validateReservedBytes(Array(bytes[10 ..< 16])) else {
            throw NESCartridgeError.invalidReservedBytes
        }
    }

    // MARK: Functions

    /// Validates flags in bytes 6-9 (console type and format compatibility)
    private func validateFlags(_ flags6: UInt8, _ flags7: UInt8, _ flags8: UInt8, _ flags9: UInt8) -> Bool {
        let consoleType = flags7 & 0x03
        let nes2Format = (flags7 & 0x0C) == 0x08
        // Allow NES file only for now !!
        return consoleType == 0 // || consoleType == 1 || consoleType == 2 || nes2Format
    }

    /// Validates reserved bytes (zero for iNES, any for NES 2.0)
    private func validateReservedBytes(_ bytes: [UInt8]) -> Bool {
        if isNES2Format {
            return true // NES 2.0 uses bytes 10-15
        }
        return bytes.allSatisfy { $0 == 0 }
    }
}
