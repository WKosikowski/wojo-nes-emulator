//
//  StatusRegisterTests.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 26/06/2025.
//

import Testing
@testable import WojoNES // Replace with your module name containing StatusRegister

struct StatusRegisterTests {
    @Test
    func testDefaultInitialization() {
        let status = StatusRegister()

        #expect(status.carry == false)
        #expect(status.zero == false)
        #expect(status.irqDisabled == false)
        #expect(status.decimal == false)
        #expect(status.break == false)
        #expect(status.unused == true)
        #expect(status.overflow == false)
        #expect(status.negative == false)
        #expect(status.value == 0x20) // Only unused bit (0x20) is set
    }

    @Test
    func testIndividualFlagSetting() {
        var status = StatusRegister()

        status.carry = true
        #expect(status.carry == true)
        #expect(status.value == 0x21) // 0x20 (unused) | 0x01 (carry)

        status.zero = true
        #expect(status.zero == true)
        #expect(status.value == 0x23) // 0x20 | 0x01 | 0x02

        status.irqDisabled = true
        #expect(status.irqDisabled == true)
        #expect(status.value == 0x27) // 0x20 | 0x01 | 0x02 | 0x04

        status.decimal = true
        #expect(status.decimal == true)
        #expect(status.value == 0x2F) // 0x20 | 0x01 | 0x02 | 0x04 | 0x08

        status.break = true
        #expect(status.break == true)
        #expect(status.value == 0x3F) // 0x20 | 0x01 | 0x02 | 0x04 | 0x08 | 0x10

        status.overflow = true
        #expect(status.overflow == true)
        #expect(status.value == 0x7F) // 0x20 | 0x01 | 0x02 | 0x04 | 0x08 | 0x10 | 0x40

        status.negative = true
        #expect(status.negative == true)
        #expect(status.value == 0xFF) // All bits set
    }

    @Test
    func testRegisterGetter() {
        var status = StatusRegister()

        // Test with all flags false (except unused)
        #expect(status.value == 0x20)

        // Set each flag individually and verify
        status.carry = true
        #expect(status.value == 0x21)

        status = StatusRegister() // Reset
        status.zero = true
        #expect(status.value == 0x22)

        status = StatusRegister()
        status.irqDisabled = true
        #expect(status.value == 0x24)

        status = StatusRegister()
        status.decimal = true
        #expect(status.value == 0x28)

        status = StatusRegister()
        status.break = true
        #expect(status.value == 0x30)

        status = StatusRegister()
        status.overflow = true
        #expect(status.value == 0x60)

        status = StatusRegister()
        status.negative = true
        #expect(status.value == 0xA0)

        // Test with all flags true
        status = StatusRegister(UInt8.max)
        #expect(status.value == 0xFF)
    }

    @Test
    func testRegisterSetter() {
        var status = StatusRegister()

        // Set register to 0x00 (should still have unused bit set)
        status.value = 0x00
        #expect(status.carry == false)
        #expect(status.zero == false)
        #expect(status.irqDisabled == false)
        #expect(status.decimal == false)
        #expect(status.break == false)
        #expect(status.unused == true)
        #expect(status.overflow == false)
        #expect(status.negative == false)
        #expect(status.value == 0x20)

        // Set all flags via register
        status.value = 0xFF
        #expect(status.carry == true)
        #expect(status.zero == true)
        #expect(status.irqDisabled == true)
        #expect(status.decimal == true)
        #expect(status.break == true)
        #expect(status.unused == true)
        #expect(status.overflow == true)
        #expect(status.negative == true)
        #expect(status.value == 0xFF)

        // Test individual bits
        status.value = 0x01
        #expect(status.carry == true)
        #expect(status.zero == false)
        #expect(status.unused == true)
        #expect(status.value == 0x21)

        status.value = 0x02
        #expect(status.carry == false)
        #expect(status.zero == true)
        #expect(status.unused == true)
        #expect(status.value == 0x22)

        // Test unused bit always true
        status.value = 0x00
        #expect(status.unused == true)
        status.value = 0xDF // 0xFF without unused bit
        #expect(status.unused == true)
        #expect(status.value == 0xFF)
    }

    @Test
    func testEdgeCases() {
        var status = StatusRegister()

        // All flags false except unused
        status.value = 0x00
        #expect(status.value == 0x20)

        // All flags true
        status.value = 0xFF
        #expect(status.value == 0xFF)

        // Alternating bits
        status.value = 0xAA // 10101010 (negative, overflow, breakFlag, zero)
        print(status.value)
        #expect(status.negative == true)
        #expect(status.overflow == false)
        #expect(status.unused == true)
        #expect(status.break == false)
        #expect(status.decimal == true)
        #expect(status.irqDisabled == false)
        #expect(status.zero == true)
        #expect(status.carry == false)
        #expect(status.value == 0xAA) // 0xAA | 0x20 (unused)
    }
}
