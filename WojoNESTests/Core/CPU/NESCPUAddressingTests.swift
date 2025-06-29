//
//  NESCPUAddressingTests.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 29/06/2025.
//
import Testing
@testable import WojoNES

@Suite("NESCPU Addressing Modes")
struct NESCPUAddressingTests {
//    @Test("Immediate Addressing Mode")
//    func testImmediate() throws {
//        let cpu = NESCPU()
//        cpu.programCounter = 0x1234
//        cpu.imm()
//        #expect(cpu.address == 0x1234)
//    }

    @Test("Zero Page Addressing Mode")
    func zeroPage() throws {
        let cpu = NESCPU()
        cpu.temporaryMemory[0x2000] = 0x42
        cpu.programCounter = 0x2000
        cpu.zpg()
        #expect(cpu.address == 0x42)
        #expect(cpu.programCounter == 0x2001)
    }

    @Test("Zero Page,X Addressing Mode Wraps Around")
    func zeroPageX() throws {
        let cpu = NESCPU()
        cpu.xRegister = 0x10
        cpu.temporaryMemory[0x1000] = 0xF5
        cpu.programCounter = 0x1000
        cpu.zpx()
        #expect(cpu.address == (0xF5 + 0x10) & 0xFF)
    }

    @Test("Relative Addressing Forward Branch")
    func relativeForward() throws {
        let cpu = NESCPU()
        cpu.temporaryMemory[0x3000] = 0x06
        cpu.programCounter = 0x3000
        cpu.rel()
        #expect(cpu.address == 0x3001 + 6)
    }

    @Test("Relative Addressing Backward Branch")
    func relativeBackward() throws {
        let cpu = NESCPU()
        cpu.temporaryMemory[0x3000] = 0xFA // -6
        cpu.programCounter = 0x3000
        cpu.rel()
        #expect(cpu.address == 0x3001 - 6)
    }

    @Test("Absolute Addressing")
    func absolute() throws {
        let cpu = NESCPU()
        cpu.temporaryMemory[0x1000] = 0x34
        cpu.temporaryMemory[0x1001] = 0x12
        cpu.programCounter = 0x1000
        cpu.abs()
        #expect(cpu.address == 0x1234)
    }

    @Test("Indirect,Y Addressing")
    func indirectY() throws {
        let cpu = NESCPU()
        cpu.yRegister = 0x04
        cpu.temporaryMemory[0x1000] = 0x10
        cpu.temporaryMemory[0x10] = 0x78
        cpu.temporaryMemory[0x11] = 0x56
        cpu.programCounter = 0x1000
        cpu.idy()
        #expect(cpu.address == 0x5678 + 0x04)
    }

    @Test("Absolute,X Addressing Mode")
    func absoluteX() throws {
        let cpu = NESCPU()
        cpu.xRegister = 0x01
        cpu.temporaryMemory[0x1000] = 0x00
        cpu.temporaryMemory[0x1001] = 0x20
        cpu.programCounter = 0x1000
        cpu.abx()
        #expect(cpu.address == 0x2000 + 0x01)
    }

    @Test("Absolute,Y Addressing Mode")
    func absoluteY() throws {
        let cpu = NESCPU()
        cpu.yRegister = 0x05
        cpu.temporaryMemory[0x1000] = 0x10
        cpu.temporaryMemory[0x1001] = 0x30
        cpu.programCounter = 0x1000
        cpu.aby()
        #expect(cpu.address == 0x3010 + 0x05)
    }

    @Test("Indexed Indirect (Indirect,X) Addressing Mode")
    func indexedIndirect() throws {
        let cpu = NESCPU()
        cpu.xRegister = 0x04
        cpu.temporaryMemory[0x1000] = 0x10
        cpu.temporaryMemory[0x14] = 0x78
        cpu.temporaryMemory[0x15] = 0x56
        cpu.programCounter = 0x1000
        cpu.idx()
        #expect(cpu.address == 0x5678)
    }

    @Test("Indirect Indexed (Indirect),Y Addressing Mode")
    func indirectIndexed() throws {
        let cpu = NESCPU()
        cpu.yRegister = 0x02
        cpu.temporaryMemory[0x1000] = 0x20
        cpu.temporaryMemory[0x20] = 0x00
        cpu.temporaryMemory[0x21] = 0x40
        cpu.programCounter = 0x1000
        cpu.idy()
        #expect(cpu.address == 0x4000 + 0x02)
    }
}
