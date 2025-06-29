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
        let lowByte = read(programCounter)
        programCounter += 1
        let highByte = read(programCounter)
        programCounter += 1
        address = (Int(highByte) << 8) | Int(lowByte)
    }

    /// absoluteX
    func abx() {
        let lowByte = read(programCounter)
        programCounter += 1
        let highByte = read(programCounter)
        programCounter += 1
        address = ((Int(highByte) << 8) | Int(lowByte)) + Int(xRegister)
    }

    /// absoluteY
    func aby() {
        let lowByte = read(programCounter)
        programCounter += 1
        let highByte = read(programCounter)
        programCounter += 1
        address = ((Int(highByte) << 8) | Int(lowByte)) + Int(yRegister)
    }

    /// indirect
    func idi() {
        let lowByte = Int(read(programCounter))
        programCounter += 1
        let highByte = Int(read(programCounter))
        programCounter += 1
        let pointer = (highByte << 8) | lowByte
        if lowByte == 0xFF {
            address = (Int(read(pointer & 0xFF00)) << 8) | Int(read(pointer))
        } else {
            address = (Int(read(pointer + 1)) << 8) | Int(read(pointer))
        }
    }

    /// indirectX
    func idx() {
        let zPAddress = read(programCounter)
        programCounter += 1
        let pointer = Int((zPAddress + xRegister) & 0xFF)
        let lowByte = Int(read(pointer))
        let highByte = Int(read((pointer + 1) & 0xFF))
        address = (highByte << 8) | lowByte
    }

    /// indirectY
    func idy() {
        let zPAddress = Int(read(programCounter))
        programCounter += 1
        let lowByte = Int(read(zPAddress))
        let highByte = Int(read((zPAddress + 1) & 0xFF))
        address = ((highByte << 8) | lowByte) + Int(yRegister)
    }
}
