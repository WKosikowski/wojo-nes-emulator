//
//  NESCartridgeError.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 02/07/2025.
//
import Foundation

/// Error types for NES cartridge validation, used when header or data parsing fails
enum NESCartridgeError: Error, LocalizedError {
    case invalidHeaderSize // Header is not 16 bytes
    case invalidMagicNumber // Magic number is not "NES" + EOF
    case invalidPRGROMSize // PRG ROM size is invalid (0 or > 4096 KB)
    case invalidCHRROMSize // CHR ROM size is invalid (< 0 or > 2048 KB)
    case invalidPRGRAMSize // PRG RAM size is invalid (< 0 or > 64 KB)
    case unsupportedMapper // Mapper number is out of range (0-255)
    case invalidHeaderFlags // Invalid flag combinations in bytes 6-9
    case invalidReservedBytes // Reserved bytes are non-zero in iNES format

    // MARK: Computed Properties

    var errorDescription: String? {
        switch self {
            case .invalidHeaderSize: return "Error: Invalid header size"
            case .invalidMagicNumber: return "Error: Invalid magic number"
            case .invalidPRGROMSize: return "Error: Invalid PRG-ROM size"
            case .invalidCHRROMSize: return "Error: Invalid CHR-ROM size"
            case .invalidPRGRAMSize: return "Error: Invalid PRG-RAM size"
            case .unsupportedMapper: return "Error: Unsupported mapper"
            case .invalidHeaderFlags: return "Error: Invalid header flags"
            case .invalidReservedBytes: return "Error: Invalid header checksum"
        }
    }
}
