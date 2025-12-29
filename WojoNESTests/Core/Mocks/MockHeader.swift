//
//  MockHeader.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 29/12/2025.
//

import Foundation
@testable import WojoNES

/// Factory function to create a valid Header for testing purposes
func MockHeader(
    prgRomBanks: UInt8 = 1,
    chrRomBanks: UInt8 = 0,
    mirroring: Header.Mirroring = .horizontal,
    hasBattery: Bool = false,
    hasTrainer: Bool = false,
    mapperNumber: UInt8 = 0
)
    -> Header
{
    // Build valid iNES header bytes
    var bytes: [UInt8] = [
        0x4E, 0x45, 0x53, 0x1A, // "NES" + MS-DOS EOF (bytes 0-3)
        prgRomBanks, // PRG ROM size in 16KB units (byte 4)
        chrRomBanks, // CHR ROM size in 8KB units (byte 5)
        0x00, // Flags 6 (byte 6)
        0x00, // Flags 7 (byte 7)
        0x00, // PRG RAM size (byte 8)
        0x00, // TV system (byte 9)
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Reserved bytes (10-15)
    ]

    // Set flags 6: mirroring (bit 0), battery (bit 1), trainer (bit 2), mapper low nibble (bits 4-7)
    var flags6: UInt8 = 0
    if mirroring == .vertical {
        flags6 |= 0x01
    }
    if hasBattery {
        flags6 |= 0x02
    }
    if hasTrainer {
        flags6 |= 0x04
    }
    flags6 |= (mapperNumber & 0x0F) << 4
    bytes[6] = flags6

    // Set flags 7: mapper high nibble (bits 4-7)
    bytes[7] = mapperNumber & 0xF0

    // Create Header - force unwrap is safe here since we control the data
    // swiftlint:disable:next force_try
    return try! Header(data: Data(bytes))
}
