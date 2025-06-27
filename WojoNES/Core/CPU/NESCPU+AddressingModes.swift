//
//  NESCPU+AddressingModes.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 27/06/2025.
//

public extension NESCPU {
    /// implied, accumulator
    func imp() {}

    /// immediate
    func imm() {
        address = read(programCounter)
        programCounter += 1
    }

    /// zeroPage
    func zpg() {
        address = read(programCounter)
        programCounter += 1
    }

    /// zeroPageX
    func zpx() {
        address = read(programCounter)
        programCounter += 1
        address = (address + xRegister) & 0xFF
    }

    /// zeroPageY
    func zpy() {
        address = read(programCounter)
        programCounter += 1
        address = (address + yRegister) & 0xFF
    }

    /// relative
    func rel() {}

    /// absolute
    func abs() {}

    /// absoluteX
    func abx() {}

    /// absoluteY
    func aby() {}

    /// indirect
    func idi() {}

    /// indirectX
    func idx() {}

    /// indirectY
    func idy() {}
}
