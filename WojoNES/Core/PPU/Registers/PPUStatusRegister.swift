//
//  PPUStatusRegister.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 19/12/2025.
//

struct PPUStatusRegister {
    // MARK: Properties

    public var spriteOverflow: Bool = false
    public var spriteZeroHit: Bool = false
    public var verticalBlank: Bool = false

    // MARK: Computed Properties

    public var register: Int {
        get {
            var result = 0
            if spriteOverflow { result |= 0x20 }
            if spriteZeroHit { result |= 0x40 }
            if verticalBlank { result |= 0x80 }
            return result
        }
        set {
            spriteOverflow = (newValue & 0x20) != 0
            spriteZeroHit = (newValue & 0x40) != 0
            verticalBlank = (newValue & 0x80) != 0
        }
    }
}
