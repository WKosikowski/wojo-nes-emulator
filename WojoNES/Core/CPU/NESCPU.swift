//
//  NESCPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 27/06/2025.
//

public final class NESCPU {
    // MARK: Properties

    /// Formerly known as A.
    var accumulator: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags()
        }
    }

    /// Formerly known as X.
    var xRegister: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags()
        }
    }

    /// Formerly known as Y.
    var yRegister: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags()
        }
    }

    /// Used for unofficial opcodes.
    var resultRegister: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags()
        }
    }

    /// Represents the Stack Pointer (SP).
    var stackPointer: UInt8 = 0
    /// Represents the Program Counter (PC). Although 6502 uses a 16-bit PC.
    var programCounter: Int = 0

    /// holds the list of all operations executable by the processor (256)
    var operations: [Operation]

    /// Holds the temporary address during opcode execution
    var address: UInt8 = 0

    // MARK: Lifecycle

    init() {
        operations = NESCPU.setupOperations()
    }

    // MARK: Functions

    func setZeroNegativeFlags() {}

    func read(_ address: Int) -> UInt8 {}
}
