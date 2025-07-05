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
    }

    /// CHR ROM size in bytes (iNES: byte 5 * 8 KB; NES 2.0: byte 9 for extended sizes)
    var chrROMSize: Int {
    }

    /// PRG RAM size in bytes (iNES: byte 8; NES 2.0: byte 10; defaults to 8 KB if 0)
    var prgRAMSize: Int {
    }

    /// CHR RAM size in bytes (8 KB if CHR ROM is absent, else 0)
    var chrRAMSize: Int {
    }

    /// Number of PRG ROM banks (16 KB each)
    var prgROMBanks: Int {
    }

    /// Number of CHR ROM banks (8 KB each)
    var chrROMBanks: Int {
    }

    /// Number of PRG RAM banks (8 KB each)
    var prgRAMBanks: Int {
    }

    /// Mapper number (lower 4 bits from byte 6, upper 4 bits from byte 7)
    var mapperNumber: Int {
    }

    /// Submapper number (NES 2.0: upper 4 bits of byte 11)
    var submapperNumber: Int {
    }

    /// Mirroring type (byte 6, bit 0)
    var mirroring: Mirroring {
    }

    /// Battery-backed RAM presence (byte 6, bit 1)
    var hasBattery: Bool {
    }

    /// Trainer presence (byte 6, bit 2; 512-byte trainer before PRG ROM)
    var hasTrainer: Bool {
    }

    /// Four-screen VRAM (ignores mirroring control; byte 6, bit 3)
    var ignoreMirrorControl: Bool {
    }

    /// NES 2.0 format detection (byte 7, bits 3-2 = 0b10)
    var isNES2Format: Bool {
    }

    /// Console type (byte 7, bits 0-1; extended for NES 2.0)
    var consoleType: ConsoleType {
    }

    /// TV system (iNES: byte 9; NES 2.0: byte 12)
    var tvSystem: TVSystem {
    }



    // MARK: - Initialisation

    /// Initialises and validates the 16-byte header
    init(data: Data) throws {
    }
}
