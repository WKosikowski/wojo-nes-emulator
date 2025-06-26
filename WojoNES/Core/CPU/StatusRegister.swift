//
//  StatusRegister.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 26/06/2025.
//

struct StatusRegister {
    // MARK: Properties

    var value: UInt8 {
        didSet {
            value |= 32
        }
    }

    // MARK: Computed Properties

    var carry: Bool {
        set {
            value = newValue ? (value | 1) : (value & ~1)
        }
        get {
            value & 1 != 0
        }
    }

    var zero: Bool {
        set {
            value = newValue ? (value | 2) : (value & ~2)
        }
        get {
            (value & 2) >> 1 != 0
        }
    }

    var irqDisabled: Bool {
        set {
            value = newValue ? (value | 4) : (value & ~4)
        }
        get {
            (value & 4) >> 2 != 0
        }
    }

    var decimal: Bool {
        set {
            value = newValue ? (value | 8) : (value & ~8)
        }
        get {
            (value & 8) >> 3 != 0
        }
    }

    var `break`: Bool {
        set {
            value = newValue ? (value | 16) : (value & ~16)
        }
        get {
            (value & 16) >> 4 != 0
        }
    }

    var unused: Bool {
        set {
            value = (value | 32)
        }
        get {
            (value & 32) >> 5 != 0
        }
    }

    var overflow: Bool {
        set {
            value = newValue ? (value | 64) : (value & ~64)
        }
        get {
            (value & 64) >> 6 != 0
        }
    }

    var negative: Bool {
        set {
            value = newValue ? (value | 128) : (value & ~128)
        }
        get {
            (value & 128) >> 7 != 0
        }
    }

    // MARK: Lifecycle

    init(_ value: UInt8 = 32) {
        self.value = value | 32
    }
}
