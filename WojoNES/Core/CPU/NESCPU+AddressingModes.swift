//
//  NESCPU+AddressingModes.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 27/06/2025.
//

public extension NESCPU {
    /// implied
    func imp() {}

    /// accumulator
    func acc() {}

    /// immediate
    func imm() {}

    /// zeroPage
    func zpg() {}

    /// zeroPageX
    func zpx() {}

    /// zeroPageY
    func zpy() {}

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
