//
//  AddressingMode.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 26/06/2025.
//

enum AddressingMode {
    case implied

    case accumulator

    case immediate

    case zeroPage
    case zeroPageX
    case zeroPageY

    case relative

    case absolute
    case absoluteX
    case absoluteY

    case indirect
    case indirectX
    case indirectY
}
