//
//  Mapper.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 23/12/2025.
//

public class Mapper {
    // MARK: Nested Types

    public enum MirrorType: Int {
        case horizontal = 0b0101_0000
        case vertical = 0b0100_0100
        case oneScreenLo = 0b0000_0000
        case oneScreenHi = 0b0101_0101
        case fourScreen = 0b1110_0100
    }

    // MARK: Properties

    public var id: Int = 0
    public var subId: Int = 0
    public var prgRAMenabled: Bool = true
    public var chrRAMenabled: Bool = false

    weak var cartridge: NESCartridge?

    private var mirroringValue: Int = 0

    // MARK: Computed Properties

    public var mirroring: MirrorType {
        get { MirrorType(rawValue: mirroringValue) ?? .horizontal }
        set {
            mirroringValue = newValue.rawValue
            cartridge?.swapNameTable(bankIdx: 3, swapBankIdx: mirroringValue >> 6)
            cartridge?.swapNameTable(bankIdx: 2, swapBankIdx: (mirroringValue >> 4) & 3)
            cartridge?.swapNameTable(bankIdx: 1, swapBankIdx: (mirroringValue >> 2) & 3)
            cartridge?.swapNameTable(bankIdx: 0, swapBankIdx: mirroringValue & 3)
        }
    }

    // MARK: Functions

    public func reset() {}
}
