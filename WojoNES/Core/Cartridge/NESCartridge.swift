//
//  NESCartridge.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 02/07/2025.
//
import Foundation

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
    var bus: Bus!

    // Cartridge memory components
    var prgMemory: BankMemory = .init()
    var chrMemory: BankMemory = .init()
    var wRam = [UInt8](repeating: 0, count: 0x2000)
    var mapper: Mapper

    // Timing information
    var timing: UInt8 = 0
    var tvSystem: TVSystem

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

    var mirroring: Header.Mirroring {
        header.mirroring
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

        // Parse timing byte (byte 12 in header) to determine TV system
        // This can override the header's TV system value
        timing = data[12]
        let timingBits = timing & 0x3
        switch timingBits {
            case 0:
                tvSystem = .ntsc
            case 1:
                tvSystem = .pal
            default:
                // For dual/multi-region, keep the header's value
                tvSystem = header.tvSystem
        }

        // Initialize cartridge memory components

        // Initialize PRG memory (pre-populate banks with full address space, then add ROM data)
        let prgBankSize = 0x4000 // 16KB
        prgMemory.banks.append(Array(repeating: 0, count: 0x8000))
        prgMemory.swapBanks.append([UInt8](prgROM))
        prgMemory.bankSizeValue = prgBankSize

        // Initialize CHR memory (pre-populate banks with full address space, then add ROM/RAM data)
        let chrBankSize = 0x2000 // 8KB
        let chrRAMEnabled = header.chrROMSize == 0
        let chrBuffer = chrRAMEnabled ?
            [UInt8](repeating: 0, count: header.chrRAMSize) :
            [UInt8](chrROM)
        chrMemory.banks.append(Array(repeating: 0, count: 0x2000))
        chrMemory.swapBanks.append(chrBuffer)
        chrMemory.bankSizeValue = chrBankSize

        // Initialize mapper based on header
        let mapperID = header.mapperNumber
        let submapper = header.submapperNumber

        switch mapperID {
            case 0: mapper = Mapper_000()
            default:
                print("Unknown mapper. Mapper ID = [\(mapperID)]")
                mapper = Mapper_000() // Fallback to mapper 0
        }

        mapper.id = mapperID
        mapper.subId = submapper
        mapper.cartridge = self
        mapper.mirroring = header.ignoreMirrorControl ? .fourScreen :
            (header.mirroring == .vertical ? .vertical : .horizontal)
        mapper.chrRAMenabled = chrRAMEnabled
        mapper.prgRAMenabled = header.prgRAMSize > 0
    }

    // MARK: Functions

    /// Swaps a nametable bank in the PPU's VRAM.
    ///
    /// This method is called by the mapper to configure nametable mirroring.
    /// It forwards the swap request to the PPU through the bus.
    ///
    /// - Parameters:
    ///   - bankIdx: Index in the nametable banks array to replace
    ///   - swapBankIdx: Index in the swap banks array to swap in
    func swapNameTable(bankIdx: Int, swapBankIdx: Int) {
        bus?.swapNameTable(bankIdx: bankIdx, swapBankIdx: swapBankIdx)
    }

    func getModel() -> NESModel {
        switch tvSystem {
            case .pal:
                return .pal
            default:
                return .ntsc
        }
    }

    func reset() {}
}
