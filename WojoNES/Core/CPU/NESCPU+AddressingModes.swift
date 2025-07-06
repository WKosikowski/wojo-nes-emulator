//
//  NESCPU+AddressingModes.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 27/06/2025.
//

public extension NESCPU {
    /// implied, accumulator
    func imp() {
        address = NESCPU.fakeAccumulatorAddress
    }

    /// immediate
    func imm() {
        address = programCounter
        programCounter = (programCounter &+ 1) & 0xFFFF
    }

    /// zeroPage
    func zpg() {
        address = Int(read(programCounter))
        programCounter = (programCounter &+ 1) & 0xFFFF
    }

    /// zeroPageX
    func zpx() {
        address = Int(read(programCounter))
        programCounter = (programCounter &+ 1) & 0xFFFF
        address = (address &+ Int(xRegister)) & 0xFF
    }

    /// zeroPageY
    func zpy() {
        address = Int(read(programCounter))
        programCounter = (programCounter &+ 1) & 0xFFFF
        address = (address &+ Int(yRegister)) & 0xFF
    }

    /// relative
    /// The relative address is computed by adding a signed 8-bit offset to the current program counter.
    func rel() {
        // Step 1: Read the next byte from memory at the current program counter (PC) location.
        // This byte is interpreted as a signed 8-bit offset for a relative jump.
        // - `read(programCounter)` returns a UInt8 (unsigned 8-bit value).
        // - `Int8(bitPattern: ...)` interprets the unsigned byte as a signed 8-bit integer.
        // - Wrapping it in `Int(...)` promotes the signed 8-bit integer to a full `Int`.
        let offset = Int(Int8(bitPattern: read(programCounter)))

        programCounter = (programCounter &+ 1) & 0xFFFF

        // Step 2: Calculate the new address by adding the signed offset to the incremented program counter.
        // - `&+` is a wrapping addition operator, which ensures that the result wraps around on overflow.
        // - This is important for simulating hardware-like behavior in constrained address spaces.
        address = (programCounter &+ offset) & 0xFFFF
    }

    /// absolute
    func abs() {
        let lowByte = read(programCounter)
        programCounter = (programCounter &+ 1) & 0xFFFF
        let highByte = read(programCounter)
        programCounter = (programCounter &+ 1) & 0xFFFF
        address = (Int(highByte) << 8) | Int(lowByte)
    }

    /// absoluteX
    func abx() {
        let lowByte = read(programCounter)
        programCounter = (programCounter &+ 1) & 0xFFFF
        let highByte = read(programCounter)
        programCounter = (programCounter &+ 1) & 0xFFFF
        address = ((Int(highByte) << 8) | Int(lowByte)) + Int(xRegister)
    }

    /// absoluteY
    func aby() {
        let lowByte = read(programCounter)
        programCounter = (programCounter &+ 1) & 0xFFFF
        let highByte = read(programCounter)
        programCounter = (programCounter &+ 1) & 0xFFFF
        address = ((Int(highByte) << 8) | Int(lowByte)) + Int(yRegister)
    }

    /// indirect
    func idi() {
        let lowByte = Int(read(programCounter))
        programCounter = (programCounter &+ 1) & 0xFFFF
        let highByte = Int(read(programCounter))
        programCounter = (programCounter &+ 1) & 0xFFFF
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
        programCounter = (programCounter &+ 1) & 0xFFFF
        let pointer = Int((zPAddress &+ xRegister) & 0xFF)
        let lowByte = Int(read(pointer))
        let highByte = Int(read((pointer + 1) & 0xFF))
        address = (highByte << 8) | lowByte
    }

    /// indirectY
    func idy() {
        let zPAddress = Int(read(programCounter))
        programCounter = (programCounter &+ 1) & 0xFFFF
        let lowByte = Int(read(zPAddress))
        let highByte = Int(read((zPAddress + 1) & 0xFF))
        address = ((highByte << 8) | lowByte) + Int(yRegister)
    }
}
