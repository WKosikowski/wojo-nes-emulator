//
//  Operation.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 26/06/2025.
//

struct Operation {
    let opCode: UInt8 // . 0-255 - all possible cpu operations
    let addressingMode: AddressingMode
    let instruction: Instruction
    let cycles: Int
}
