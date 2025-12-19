//
//  VramRegisterTests 2.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 19/12/2025.
//

import Testing
@testable import WojoNES

@Suite("PPU")
struct VramRegisterTests {
    // MARK: - fineYValue Tests

    @Test
    func fineYValue_getAndSet_updatesFineY() {
        var vram = VramRegister()
        vram.fineYValue = 5

        #expect(vram.fineYValue == 5)
    }

    @Test
    func fineYValue_setsA12ToggledOnRisingLSB() {
        var vram = VramRegister(fineY: 0)
        vram.fineYValue = 1

        #expect(vram.a12Toggled == true)
    }

    @Test
    func fineYValue_doesNotToggleA12WhenNoRisingEdge() {
        var vram = VramRegister(fineY: 1)
        vram.fineYValue = 3

        #expect(vram.a12Toggled == false)
    }

    @Test
    func fineYValue_fallingEdgeDoesNotToggleA12() {
        var vram = VramRegister(fineY: 1)
        vram.fineYValue = 0

        #expect(vram.a12Toggled == false)
    }

    // MARK: - Address Tests

    @Test
    func address_get_packsAllFieldsCorrectly() {
        let vram = VramRegister(
            fineY: 3,
            coarseX: 10,
            coarseY: 12,
            nameTableX: 1,
            nameTableY: 0
        )

        let expected =
            (3 << 12) |
            (0 << 11) |
            (1 << 10) |
            (12 << 5) |
            10

        #expect(vram.address == expected)
    }

    @Test
    func address_set_unpacksAllFieldsCorrectly() {
        var vram = VramRegister()
        vram.address = 0b101_1010_0100_1101

        #expect(vram.fineYValue == 0b101)
        #expect(vram.nameTableY == 1)
        #expect(vram.nameTableX == 0)
        #expect(vram.coarseY == 0b10010)
        #expect(vram.coarseX == 0b01101)
    }

    @Test
    func address_set_masksFineYTo3Bits() {
        var vram = VramRegister()
        vram.address = 0xFFFF

        #expect(vram.fineYValue <= 7)
    }

    @Test
    func address_roundTripConsistency() {
        var vram = VramRegister()
        vram.address = 0x3ABC

        let result = vram.address
        #expect(result == (0x3ABC & 0x7FFF))
    }

    // MARK: - Scroll X Tests

    @Test
    func scrollX_get_packsFieldsCorrectly() {
        let vram = VramRegister(
            fineX: 3,
            coarseX: 12,
            nameTableX: 1
        )

        let expected = (1 << 8) | (12 << 3) | 3
        #expect(vram.scrollX == expected)
    }

    @Test
    func scrollX_set_unpacksFieldsCorrectly() {
        var vram = VramRegister()
        vram.scrollX = 0b1_1010_1110

        #expect(vram.nameTableX == 1)
        #expect(vram.coarseX == 0b10101)
        #expect(vram.fineX == 0b110)
    }

    // MARK: - Scroll Y Tests

    @Test
    func scrollY_get_packsFieldsCorrectly() {
        let vram = VramRegister(
            fineY: 6,
            coarseY: 18,
            nameTableY: 1
        )

        let expected = (1 << 8) | (18 << 3) | 6
        #expect(vram.scrollY == expected)
    }

    @Test
    func scrollY_set_unpacksFieldsCorrectly() {
        var vram = VramRegister()
        vram.scrollY = 0b0_0101_0011

        #expect(vram.nameTableY == 0)
        #expect(vram.coarseY == 0b01010)
        #expect(vram.fineYValue == 0b011)
    }

    // MARK: - Latch-Based Behavior

    @Test
    func setAddress_firstWriteSetsHighByte() {
        var vram = VramRegister()
        vram.setAddress(0x12)

        #expect(vram.latched == true)
        #expect(vram.address & 0xFF00 == 0x1200)
    }

    @Test
    func setAddress_secondWriteSetsLowBits() {
        var vram = VramRegister()
        vram.setAddress(0x12)
        vram.setAddress(0x34)

        #expect(vram.latched == false)
        #expect(vram.coarseX == (0x34 & 0x1F))
    }

    @Test
    func setScroll_firstWriteSetsXScroll() {
        var vram = VramRegister()
        vram.setScroll(0b1010_1111)

        #expect(vram.fineX == 0b111)
        #expect(vram.coarseX == 0b10101)
    }

    @Test
    func setScroll_secondWriteSetsYScroll() {
        var vram = VramRegister()
        vram.setScroll(0x00)
        vram.setScroll(0b0101_0100)

        #expect(vram.fineYValue == 0b100)
        #expect(vram.coarseY == 0b01010)
    }
}
