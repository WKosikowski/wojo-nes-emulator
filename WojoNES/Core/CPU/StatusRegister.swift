//
//  StatusRegister.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 26/06/2025.
//

struct StatusRegister {
    var carry: Bool = false
    var zero: Bool = false
    var irqDisabled: Bool = false
    var decimal: Bool = false
    var `break`: Bool = false
    var unused: Bool = false
    var overflow: Bool = false
    var negative: Bool = false
    var value: UInt8 = 0
}
