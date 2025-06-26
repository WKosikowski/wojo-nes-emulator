//
//  StatusRegister.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 26/06/2025.
//

struct StatusRegister {
    // MARK: Properties

    var carry: Bool {
        didSet { updateValue() }
    }

    var zero: Bool {
        didSet { updateValue() }
    }

    var irqDisabled: Bool {
        didSet { updateValue() }
    }

    var decimal: Bool {
        didSet { updateValue() }
    }

    var `break`: Bool {
        didSet { updateValue() }
    }

    var unused: Bool {
        didSet { updateValue() }
    }

    var overflow: Bool {
        didSet { updateValue() }
    }

    var negative: Bool {
        didSet { updateValue() }
    }

    var value: UInt8 {
        didSet { updateFlags() }
    }

    // MARK: Lifecycle

    init() {
        carry = false
        zero = false
        irqDisabled = false
        decimal = false
        self.break = false
        unused = false
        overflow = false
        negative = false
        value = 0
    }

    // MARK: Functions

    private mutating func updateValue() {
        var value = 0
        if carry { value |= 1 << 0 }
        if zero { value |= 1 << 1 }
        if irqDisabled { value |= 1 << 2 }
        if decimal { value |= 1 << 3 }
        if `break` { value |= 1 << 4 }
        if unused { value |= 1 << 5 }
        if overflow { value |= 1 << 6 }
        if negative { value |= 1 << 7 }
    }

    private mutating func updateFlags() {
        carry = (value & (1 << 0)) != 0
        zero = (value & (1 << 1)) != 0
        irqDisabled = (value & (1 << 2)) != 0
        decimal = (value & (1 << 3)) != 0
        `break` = (value & (1 << 4)) != 0
        unused = (value & (1 << 5)) != 0
        overflow = (value & (1 << 6)) != 0
        negative = (value & (1 << 7)) != 0
    }
}
