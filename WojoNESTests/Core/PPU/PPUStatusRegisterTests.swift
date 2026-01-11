//
//  PPUStatusRegisterTests.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 19/12/2025.
//

import Testing
@testable import WojoNES

@Suite("PPU")
struct PPUStatusRegisterTests {
    @Test("Set Value spriteOverflow True")
    func spriteOverflowTrue() {
        var statusRegister = PPUStatusRegister()
        statusRegister.value = 0x20
        #expect(statusRegister.spriteOverflow == true)
        #expect(statusRegister.spriteZeroHit == false)
        #expect(statusRegister.verticalBlank == false)
    }

    @Test("Set Value spriteZeroHit True")
    func spriteZeroHitTrue() {
        var statusRegister = PPUStatusRegister()
        statusRegister.value = 0x40
        #expect(statusRegister.spriteOverflow == false)
        #expect(statusRegister.spriteZeroHit == true)
        #expect(statusRegister.verticalBlank == false)
    }

    @Test("Set Value verticalBlank True")
    func verticalBlankTrue() {
        var statusRegister = PPUStatusRegister()
        statusRegister.value = 0x80
        #expect(statusRegister.spriteOverflow == false)
        #expect(statusRegister.spriteZeroHit == false)
        #expect(statusRegister.verticalBlank == true)
    }

    @Test("Set Value all True")
    func allFlagsTrue() {
        var statusRegister = PPUStatusRegister()
        statusRegister.value = 0x20 + 0x40 + 0x80
        #expect(statusRegister.spriteOverflow == true)
        #expect(statusRegister.spriteZeroHit == true)
        #expect(statusRegister.verticalBlank == true)
    }

    @Test("Get Value all false")
    func valueGetter_allFlagsFalse() {
        var status = PPUStatusRegister()
        status.spriteOverflow = false
        status.spriteZeroHit = false
        status.verticalBlank = false

        #expect(status.value == 0x00)
    }

    @Test("Get Value spriteOverflow true")
    func valueGetter_spriteOverflowTrue() {
        var status = PPUStatusRegister()
        status.spriteOverflow = true
        status.spriteZeroHit = false
        status.verticalBlank = false

        #expect(status.value == 0x20)
    }

    @Test("Get Value SpriteZeroHit True")
    func valueGetter_spriteZeroHitOnly() {
        var status = PPUStatusRegister()
        status.spriteOverflow = false
        status.spriteZeroHit = true
        status.verticalBlank = false

        #expect(status.value == 0x40)
    }

    @Test("Get Value all true")
    func valueGetter_allFlagsTrue() {
        var status = PPUStatusRegister()
        status.spriteOverflow = true
        status.spriteZeroHit = true
        status.verticalBlank = true

        #expect(status.value == 0xE0)
    }
}
