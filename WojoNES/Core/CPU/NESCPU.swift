//
//  NESCPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 27/06/2025.
//

public final class NESCPU {
    // MARK: Properties

    var statusRegister = StatusRegister()

    /// Formerly known as A.
    var accumulator: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags(accumulator)
        }
    }

    /// Formerly known as X.
    var xRegister: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags(xRegister)
        }
    }

    /// Formerly known as Y.
    var yRegister: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags(yRegister)
        }
    }

    /// Used for unofficial opcodes.
    var resultRegister: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags(resultRegister)
        }
    }

    /// Represents the Stack Pointer (SP).
    var stackPointer: UInt8 = 0xFF
    /// Represents the Program Counter (PC). Although 6502 uses a 16-bit PC.
    var programCounter: Int = 0

    /// holds the list of all operations executable by the processor (256)
    var operations: [Operation]

    /// Holds the temporary address during opcode execution
    var address: Int = 0

    /// needed for tests, will be removed later
    var temporaryMemory: [UInt8] = Array(repeating: 0, count: 0x10000)

    // MARK: Lifecycle

    init() {
        operations = NESCPU.setupOperations()
    }

    // MARK: Functions

    func setZeroNegativeFlags(_ register: UInt8) {
        statusRegister.zero = register == 0
        statusRegister.negative = register & 0b1000_0000 != 0
    }

    func read(_ address: Int) -> UInt8 {
        temporaryMemory[address]
    }

    func write(_ address: Int, _ value: UInt8) {
        temporaryMemory[address] = value
    }

    func pushToStack(_ value: UInt8) {
        write(Int(stackPointer) | 0x100, value)
        if stackPointer == 0 {
            stackPointer = 0xFF
        } else {
            stackPointer -= 1
        }
    }

    func popFromStack() -> UInt8 {
        stackPointer += 1
        return read(Int(stackPointer))
    }

    func cmp(_ reg: UInt8, _ mem: UInt8) {
        statusRegister.carry = reg >= mem
        resultRegister = UInt8(reg &- mem)
    }
}
