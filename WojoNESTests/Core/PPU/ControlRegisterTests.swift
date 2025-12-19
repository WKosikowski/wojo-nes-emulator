//
//  ControlRegisterTests.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 19/12/2025.
//

import Testing
@testable import WojoNES

@Suite("PPU Control Register")
struct ControlRegisterTests {
    // MARK: - NameTable Selection Tests

    @Test("NameTable X bit 0 sets correctly")
    func nameTableXBit0() {
        var control = ControlRegister()
        control.value = 0x01
        #expect(control.nameTableX == 1)
        #expect(control.nameTableY == 0)
    }

    @Test("NameTable Y bit 1 sets correctly")
    func nameTableYBit1() {
        var control = ControlRegister()
        control.value = 0x02
        #expect(control.nameTableX == 0)
        #expect(control.nameTableY == 1)
    }

    @Test("NameTable X and Y both set")
    func nameTableBoth() {
        var control = ControlRegister()
        control.value = 0x03 // bits 0 and 1 set
        #expect(control.nameTableX == 1)
        #expect(control.nameTableY == 1)
    }

    // MARK: - VRAM Increment Tests

    @Test("VRAM increment bit 2 = 1 maps to 32")
    func vramIncrementBit2Set() {
        var control = ControlRegister()
        control.value = 0x04
        #expect(control.increment == 32)
    }

    @Test("VRAM increment bit 2 = 0 maps to 1")
    func vramIncrementBit2Clear() {
        var control = ControlRegister()
        control.value = 0x00
        #expect(control.increment == 1)
    }

    // MARK: - Pattern Table Selection Tests

    @Test("Sprite pattern table bit 3 sets correctly")
    func spritePatternTableBit3() {
        var control = ControlRegister()
        control.value = 0x08
        #expect(control.patternSprite == 1)
        #expect(control.patternBg == 0)
    }

    @Test("Background pattern table bit 4 sets correctly")
    func backgroundPatternTableBit4() {
        var control = ControlRegister()
        control.value = 0x10
        #expect(control.patternSprite == 0)
        #expect(control.patternBg == 1)
    }

    @Test("Both pattern tables set")
    func bothPatternTablesSet() {
        var control = ControlRegister()
        control.value = 0x18 // bits 3 and 4 set
        #expect(control.patternSprite == 1)
        #expect(control.patternBg == 1)
    }

    // MARK: - Sprite Size Tests

    @Test("Sprite size bit 5 = 0 maps to 8")
    func spriteSizeBit5Clear() {
        var control = ControlRegister()
        control.value = 0x00
        #expect(control.spriteSize == 8)
    }

    @Test("Sprite size bit 5 = 1 maps to 16")
    func spriteSizeBit5Set() {
        var control = ControlRegister()
        control.value = 0x20
        #expect(control.spriteSize == 16)
    }

    // MARK: - Master/Slave Tests

    @Test("Slave mode bit 6 sets correctly")
    func slaveBit6() {
        var control = ControlRegister()
        control.value = 0x40
        #expect(control.slaveMode == true)
    }

    @Test("Slave mode bit 6 clear")
    func slaveBit6Clear() {
        var control = ControlRegister()
        control.value = 0x00
        #expect(control.slaveMode == false)
    }

    // MARK: - NMI Enable Tests

    @Test("NMI enable bit 7 sets correctly")
    func nmiEnableBit7() {
        var control = ControlRegister()
        control.value = 0x80
        #expect(control.enableNMI == true)
    }

    @Test("NMI enable bit 7 clear")
    func nmiEnableBit7Clear() {
        var control = ControlRegister()
        control.value = 0x00
        #expect(control.enableNMI == false)
    }

    // MARK: - Combined Register Tests

    @Test("All bits set produces 0xFF")
    func allBitsSet() {
        var control = ControlRegister()
        control.value = 0xFF
        #expect(control.nameTableX == 1)
        #expect(control.nameTableY == 1)
        #expect(control.increment == 32)
        #expect(control.patternSprite == 1)
        #expect(control.patternBg == 1)
        #expect(control.spriteSize == 16)
        #expect(control.slaveMode == true)
        #expect(control.enableNMI == true)
    }

    @Test("All bits clear produces 0x00")
    func allBitsClear() {
        var control = ControlRegister()
        control.value = 0x00
        #expect(control.nameTableX == 0)
        #expect(control.nameTableY == 0)
        #expect(control.increment == 1)
        #expect(control.patternSprite == 0)
        #expect(control.patternBg == 0)
        #expect(control.spriteSize == 8)
        #expect(control.slaveMode == false)
        #expect(control.enableNMI == false)
    }

    @Test("Packing individual fields produces correct register value")
    func packingIndividualFields() {
        var control = ControlRegister()
        control.nameTableX = 1
        control.nameTableY = 1
        control.increment = 32
        control.patternSprite = 1
        control.patternBg = 1
        control.spriteSize = 16
        control.slaveMode = true
        control.enableNMI = true
        #expect(control.value == 0xFF)
    }

    @Test("Specific register value 0x5A unpacks correctly")
    func unpackSpecificValue() {
        var control = ControlRegister()
        control.value = 0x5A // 01011010
        #expect(control.nameTableX == 0) // bit 0: 0
        #expect(control.nameTableY == 1) // bit 1: 1
        #expect(control.increment == 32) // bit 2: 1
        #expect(control.patternSprite == 1) // bit 3: 1
        #expect(control.patternBg == 0) // bit 4: 0
        #expect(control.spriteSize == 16) // bit 5: 1
        #expect(control.slaveMode == false) // bit 6: 0
        #expect(control.enableNMI == true) // bit 7: 1
    }

    @Test("Round-trip: set fields then read register")
    func roundTripSetFieldsReadRegister() {
        var control = ControlRegister()
        control.nameTableX = 1
        control.patternBg = 1
        control.enableNMI = true
        let packed = control.value

        var control2 = ControlRegister()
        control2.value = packed
        #expect(control2.nameTableX == 1)
        #expect(control2.patternBg == 1)
        #expect(control2.enableNMI == true)
    }

    @Test("Default initialization produces register value 0x00")
    func defaultInitialization() {
        let control = ControlRegister()
        #expect(control.value == 0x00)
    }

    @Test("Modify single field doesn't affect others")
    func modifySingleFieldIsolation() {
        var control = ControlRegister()
        control.value = 0xFF
        control.enableNMI = false
        #expect(control.value == 0x7F) // 0xFF with bit 7 cleared
        #expect(control.nameTableX == 1)
        #expect(control.patternSprite == 1)
    }
}
