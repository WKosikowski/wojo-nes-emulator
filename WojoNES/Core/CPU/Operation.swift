//
//  Operation.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 26/06/2025.
//

struct Operation {
    // MARK: Properties

    let opCode: UInt8 // . 0-255 - all possible cpu operations
    let name: String
    let addressingMode: AddressingMode
    let instruction: Instruction
    let cycles: Int

    // MARK: Lifecycle

    init(_ opCode: UInt8, _ name: String, _ addressingMode: AddressingMode, _ instruction: Instruction, _ cycles: Int) {
        self.opCode = opCode
        self.name = name
        self.addressingMode = addressingMode
        self.instruction = instruction
        self.cycles = cycles
    }
}
