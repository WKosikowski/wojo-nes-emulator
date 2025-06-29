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
        address = Int(read(programCounter))
        programCounter += 1
    }

    /// zeroPage
    func zpg() {
        address = Int(read(programCounter))
        programCounter += 1
    }

    /// zeroPageX
    func zpx() {
        address = Int(read(programCounter))
        programCounter += 1
        address = (address + Int(xRegister)) & 0xFF
    }

    /// zeroPageY
    func zpy() {
        address = Int(read(programCounter))
        programCounter += 1
        address = (address + Int(yRegister)) & 0xFF
    }

    /// relative
    func rel() {
        let offset = Int(Int8(bitPattern: read(programCounter)))
        programCounter += 1
        address = programCounter &+ offset
    }

    /// absolute
    func abs() {
        let lowBit = read(programCounter)
        programCounter += 1
        let highBit = read(programCounter)
        programCounter += 1
        address = Int((highBit << 8) | lowBit)
    }

    /// absoluteX
    func abx() {
        let lowBit = read(programCounter)
        programCounter += 1
        let highBit = read(programCounter)
        programCounter += 1
        address = Int(((highBit << 8) | lowBit) + xRegister)
    }

    /// absoluteY
    func aby() {
        let lowByte = read(programCounter)
        programCounter += 1
        let highByte = read(programCounter)
        programCounter += 1
        address = Int(((highByte << 8) | lowByte) + yRegister)
    }

    /// indirect
    func idi() {
        let lowByte = read(programCounter)
        programCounter += 1
        let highByte = read(programCounter)
        programCounter += 1
        let pointer = Int((highByte << 8) | lowByte)
        if lowByte == 0xFF {
            address = Int((read(pointer & 0xFF00) << 8) | read(pointer))
        } else {
            address = Int((read(pointer + 1) << 8) | read(pointer))
        }
    }

    /// indirectX
    func idx() {
        let zPAddress = read(programCounter)
        programCounter += 1
        let pointer = Int((zPAddress + xRegister) & 0xFF)
        let lowByte = read(pointer)
        let highByte = read((pointer + 1) & 0xFF)
        address = Int((highByte << 8) | lowByte)
    }

    /// indirectY
    func idy() {
        let zPAddress = Int(read(programCounter))
        programCounter += 1
        let lowByte = read(zPAddress)
        let highByte = read((zPAddress + 1) & 0xFF)
        address = Int(((highByte << 8) | lowByte) + yRegister)
    }
}
