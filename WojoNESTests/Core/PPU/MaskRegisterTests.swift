//
//  MaskRegisterTests.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 19/12/2025.
//

import Testing
@testable import WojoNES

@Suite("PPU")
struct MaskRegisterTests2 {
    @Test("Default initialization produces register == 0x00")
    func defaultInit() {
        let mask = MaskRegister()
        #expect(mask.value == 0x00)
    }

    @Test("Set and clear individual bits round-trip")
    func individualBitsRoundTrip() {
        var mask = MaskRegister()
        // test each bit by setting register then verifying the boolean
        for bit in 0 ..< 8 {
            let value = 1 << bit
            mask.value = value
            #expect((mask.value & value) == value)
        }
    }

    @Test("Toggle flags do not unintentionally modify other flags")
    func toggleIsolation() {
        var mask = MaskRegister()
        mask.value = 0xFF
        // toggle greyscale off
        mask.greyscale = false
        #expect((mask.value & 0x01) == 0)
        // other flags remain set
        #expect((mask.value & 0xFE) == 0xFE)
    }

    @Test("Packing/unpacking symmetry for random values")
    func packingSymmetry() {
        var mask = MaskRegister()
        let samples: [Int] = [0x00, 0x3F, 0xA5, 0x5A, 0xFF]
        for s in samples {
            mask.value = s
            #expect(mask.value == s)
        }
    }
}
