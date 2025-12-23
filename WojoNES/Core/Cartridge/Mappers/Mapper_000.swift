//
//  Mapper 2.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 23/12/2025.
//

public class Mapper_000: Mapper {
    override public func reset() {
        cartridge?.chrMemory.bankSizeValue = 0x1000
        cartridge?.prgMemory.swap(bankIdx: 1, swapBankIdx: -1)
    }
}
