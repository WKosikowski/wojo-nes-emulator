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
}
