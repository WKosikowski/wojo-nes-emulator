//
//  NESCartridge.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 02/07/2025.
//
import Foundation

// MARK: - NESCartridge

/// Represents an NES cartridge, including header and ROM data
struct NESCartridge {
    // MARK: Static Properties

    let header: Header // Parsed header data
    let prgROM: Data // PRG ROM data
    let chrROM: Data // CHR ROM data
    let trainer: Data? // Trainer data (512 bytes, if present)

    // MARK: Lifecycle

    /// Initialises the cartridge from NES file data
    init(data: Data) throws {
    }
}
