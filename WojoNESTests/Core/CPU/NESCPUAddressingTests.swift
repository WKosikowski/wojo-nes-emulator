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

    // Helper function to properly initialize CPU for testing
    func setupCPU() -> (NESCPU, MockBus) {
        let cpu = NESCPU()
        let bus = MockBus()
        let apu = MockAPU()
        let ppu = MockPPU()
        
        cpu.connect(bus)
        bus.connect(apu)
        bus.connect(ppu)

        // Initialize interrupts to prevent crashes
        cpu.addNmiInterrupt(Interrupt())
        cpu.addApuIrqInterrupt(Interrupt())
        cpu.addDmcIrqInterrupt(Interrupt())

        // Set a default current operation to avoid nil crash in readPageCross
        // Using NOP with no read cycle for most tests
        cpu.currentOperation = Operation(0xEA, "NOP", .implied, .nop, 2, false)

        return (cpu, bus)
    }

    @Test("Immediate Addressing Mode")
    func immediate() throws {
        let (cpu, _) = setupCPU()
        cpu.programCounter = 0x1234
        cpu.imm()
        #expect(cpu.address == 0x1234)
    }

    @Test("Zero Page Addressing Mode")
    func zeroPage() throws {
        let (cpu, bus) = setupCPU()
        bus.write(address: 0x1000, data: 0x42)
        cpu.programCounter = 0x1000
        cpu.zpg()
        #expect(cpu.address == 0x42)
        #expect(cpu.programCounter == 0x1001)
    }

    @Test("Zero Page Addressing: wrap programCounter at 0xFFFF")
    func zeroPageProgramCounterWrap() throws {
        let (cpu, bus) = setupCPU()
        bus.write(address: 0xFFFF, data: 0x05)
        cpu.programCounter = 0xFFFF
        cpu.zpg()
        #expect(cpu.address == 0x05)
        #expect(cpu.programCounter == 0x0000)
    }

    @Test("Zero Page,X Addressing wraps at 0xFF")
    func zeroPageXWraps() throws {
        let (cpu, bus) = setupCPU()
        cpu.xRegister = 0xFF
        bus.write(address: 0x1000, data: 0x80)
        bus.write(address: 0x80, data: 0x00) // dummy read location
        cpu.programCounter = 0x1000
        cpu.zpx()
        #expect(cpu.address == (0x80 + 0xFF) & 0xFF)
    }

    @Test("Zero Page,X Addressing Mode Wraps Around")
    func zeroPageX() throws {
        let (cpu, bus) = setupCPU()
        cpu.xRegister = 0x10
        bus.write(address: 0x1000, data: 0xF5)
        bus.write(address: 0xF5, data: 0x00) // dummy read location
        cpu.programCounter = 0x1000
        cpu.zpx()
        #expect(cpu.address == (0xF5 + 0x10) & 0xFF)
    }

    @Test("Relative Addressing Forward Branch")
    func relativeForward() throws {
        let (cpu, bus) = setupCPU()
        bus.write(address: 0x1000, data: 0x06)
        cpu.programCounter = 0x1000
        cpu.rel()
        #expect(cpu.address == 0x1001 + 6)
    }

    @Test("Relative Branch: max forward (+127)")
    func relativeForwardMax() throws {
        let (cpu, bus) = setupCPU()
        bus.write(address: 0x2000, data: 0x7F) // +127
        cpu.programCounter = 0x2000
        cpu.rel()
        #expect(cpu.address == 0x2001 + 127)
    }

    @Test("Relative Addressing Backward Branch")
    func relativeBackward() throws {
        let (cpu, bus) = setupCPU()
        bus.write(address: 0x1000, data: 0xFA) // -6
        cpu.programCounter = 0x1000
        cpu.rel()
        #expect(cpu.address == 0x1001 - 6)
    }

    @Test("Relative Branch: max backward (-128)")
    func relativeBackwardMax() throws {
        let (cpu, bus) = setupCPU()
        bus.write(address: 0x2000, data: 0x80) // -128 (0x80 in 2's comp)
        cpu.programCounter = 0x2000
        cpu.rel()
        #expect(cpu.address == 0x2001 - 128)
    }

    @Test("Absolute Addressing")
    func absolute() throws {
        let (cpu, bus) = setupCPU()
        bus.write(address: 0x1000, data: 0x34)
        bus.write(address: 0x1001, data: 0x12)
        cpu.programCounter = 0x1000
        cpu.abs()
        #expect(cpu.address == 0x1234)
    }

    @Test("Indirect,Y Addressing")
    func indirectY() throws {
        let (cpu, bus) = setupCPU()
        cpu.yRegister = 0x04
        bus.write(address: 0x1000, data: 0x10)
        bus.write(address: 0x10, data: 0x78)
        bus.write(address: 0x11, data: 0x56)
        cpu.programCounter = 0x1000
        cpu.idy()
        #expect(cpu.address == 0x5678 + 0x04)
    }

    @Test("Absolute,X Addressing Mode")
    func absoluteX() throws {
        let (cpu, bus) = setupCPU()
        cpu.xRegister = 0x01
        bus.write(address: 0x1000, data: 0x00)
        bus.write(address: 0x1001, data: 0x20)
        cpu.programCounter = 0x1000
        cpu.abx()
        #expect(cpu.address == 0x2000 + 0x01)
    }

    @Test("Absolute,Y Addressing Mode")
    func absoluteY() throws {
        let (cpu, bus) = setupCPU()
        cpu.yRegister = 0x05
        bus.write(address: 0x0800, data: 0x10)
        bus.write(address: 0x0801, data: 0x30)
        cpu.programCounter = 0x0800
        cpu.aby()
        #expect(cpu.address == 0x3010 + 0x05)
    }

    @Test("Indexed Indirect (Indirect,X) Addressing Mode")
    func indexedIndirect() throws {
        let (cpu, bus) = setupCPU()
        cpu.xRegister = 0x04
        bus.write(address: 0x1000, data: 0x10)
        bus.write(address: 0x10, data: 0x00) // dummy read location
        bus.write(address: 0x14, data: 0x78)
        bus.write(address: 0x15, data: 0x56)
        cpu.programCounter = 0x1000
        cpu.idx()
        #expect(cpu.address == 0x5678)
    }

    @Test("Indexed Indirect (Indirect,X) Mode: pointer wrap at 0xFF")
    func indexedIndirectPointerWraps() throws {
        let (cpu, bus) = setupCPU()
        cpu.xRegister = 0x01
        // Pointer will be (0xFF + 1) & 0xFF == 0x00
        bus.write(address: 0x1000, data: 0xFF)
        bus.write(address: 0xFF, data: 0x00) // dummy read location
        bus.write(address: 0x00, data: 0x34) // low byte at 0x00
        bus.write(address: 0x01, data: 0x12) // high byte at 0x01 (correct wraparound)
        cpu.programCounter = 0x1000
        cpu.idx()
        #expect(cpu.address == 0x1234)
    }

    @Test("Indexed Indirect (Indirect,X) Mode: pointer base at 0x00, xRegister=0")
    func indexedIndirectPointerAtZero() throws {
        let (cpu, bus) = setupCPU()
        cpu.xRegister = 0x00
        bus.write(address: 0x1000, data: 0x10)
        bus.write(address: 0x10, data: 0x00) // dummy read location
        bus.write(address: 0x10, data: 0xAB) // low byte
        bus.write(address: 0x11, data: 0xCD) // high byte
        cpu.programCounter = 0x1000
        cpu.idx()
        #expect(cpu.address == 0xCDAB)
    }

    @Test("Indexed Indirect (Indirect,X) Mode: pointer at 0xFE, X=1 (wrap pointer)")
    func indexedIndirectPointerNearEndWrap() throws {
        let (cpu, bus) = setupCPU()
        cpu.xRegister = 0x01
        bus.write(address: 0x1000, data: 0xFE)
        bus.write(address: 0xFE, data: 0x00) // dummy read location
        bus.write(address: 0xFF, data: 0xEE) // low byte
        bus.write(address: 0x00, data: 0xDD) // high byte (wraps)
        cpu.programCounter = 0x1000
        cpu.idx()
        #expect(cpu.address == 0xDDEE)
    }

    @Test("Indexed Indirect (Indirect,X) Mode: pointer at 0xFF, X=0 (high byte from 0x00)")
    func indexedIndirectPointerAtFF() throws {
        let (cpu, bus) = setupCPU()
        cpu.xRegister = 0x00
        bus.write(address: 0x1000, data: 0xFF)
        bus.write(address: 0xFF, data: 0x00) // dummy read location
        bus.write(address: 0xFF, data: 0x01)
        bus.write(address: 0x00, data: 0x02) // wrap-around high
        cpu.programCounter = 0x1000
        cpu.idx()
        #expect(cpu.address == 0x0201)
    }

    @Test("Indirect Indexed (Indirect),Y Addressing Mode")
    func indirectIndexed() throws {
        let (cpu, bus) = setupCPU()
        cpu.yRegister = 0x02
        bus.write(address: 0x1000, data: 0x20)
        bus.write(address: 0x20, data: 0x00)
        bus.write(address: 0x21, data: 0x40)
        cpu.programCounter = 0x1000
        cpu.idy()
        #expect(cpu.address == 0x4000 + 0x02)
    }

    @Test("Absolute,X Addressing Mode - Page Crossing")
    func absoluteXPageCrossing() throws {
        let (cpu, bus) = setupCPU()
        cpu.xRegister = 0x01
        // Base address is 0x20FF, adding 0x01 crosses to 0x2100
        bus.write(address: 0x1000, data: 0xFF) // low byte
        bus.write(address: 0x1001, data: 0x20) // high byte
        // Add dummy read location for page crossing
        bus.write(address: 0x2000, data: 0x00) // page crossing dummy read
        cpu.programCounter = 0x1000
        cpu.abx()
        #expect(cpu.address == 0x2100)
    }

    @Test("Absolute,Y Addressing Mode - Page Crossing")
    func absoluteYPageCrossing() throws {
        let (cpu, bus) = setupCPU()
        cpu.yRegister = 0x10
        // Base address is 0x30FD, adding 0x10 crosses to 0x310D
        bus.write(address: 0x0800, data: 0xFD) // low byte
        bus.write(address: 0x0801, data: 0x30) // high byte
        // Add dummy read location for page crossing
        bus.write(address: 0x300D, data: 0x00) // page crossing dummy read
        cpu.programCounter = 0x0800
        cpu.aby()
        #expect(cpu.address == 0x310D)
    }

    @Test("Indirect Indexed (Indirect),Y Addressing - Page Crossing")
    func indirectIndexedPageCrossing() throws {
        let (cpu, bus) = setupCPU()
        cpu.yRegister = 0x10
        // Pointer at 0x20: 0x00FD, adding Y crosses to 0x010D
        bus.write(address: 0x1000, data: 0x20) // pointer addr
        bus.write(address: 0x20, data: 0xFD) // low byte
        bus.write(address: 0x21, data: 0x00) // high byte
        // Add dummy read location for page crossing
        bus.write(address: 0x000D, data: 0x00) // page crossing dummy read
        cpu.programCounter = 0x1000
        cpu.idy()
        #expect(cpu.address == 0x010D)
    }

    @Test("Immediate Addressing Mode: programCounter wrap at 0xFFFF")
    func immediateProgramCounterWrap() throws {
        let (cpu, _) = setupCPU()
        cpu.programCounter = 0xFFFF
        cpu.imm()
        #expect(cpu.address == 0xFFFF)
        #expect(cpu.programCounter == 0x0000)
    }

    @Test("Zero Page,X Addressing: programCounter wrap at 0xFFFF")
    func zeroPageXProgramCounterWrap() throws {
        let (cpu, bus) = setupCPU()
        cpu.xRegister = 0x03
        bus.write(address: 0xFFFF, data: 0x80)
        bus.write(address: 0x80, data: 0xFF) // dummy read location
        cpu.programCounter = 0xFFFF
        cpu.zpx()
        #expect(cpu.address == (0x80 + 0x03) & 0xFF)
        #expect(cpu.programCounter == 0x0000)
    }

    @Test("Zero Page,Y Addressing: programCounter wrap at 0xFFFF")
    func zeroPageYProgramCounterWrap() throws {
        let (cpu, bus) = setupCPU()
        cpu.yRegister = 0x02
        bus.write(address: 0xFFFF, data: 0x90)
        bus.write(address: 0x90, data: 0xFF) // dummy read location
        cpu.programCounter = 0xFFFF
        cpu.zpy()
        #expect(cpu.address == (0x90 + 0x02) & 0xFF)
        #expect(cpu.programCounter == 0x0000)
    }

    @Test("Relative Addressing: programCounter wrap at 0xFFFF")
    func relativeProgramCounterWrap() throws {
        let (cpu, bus) = setupCPU()
        bus.write(address: 0xFFFF, data: 0x06)
        cpu.programCounter = 0xFFFF
        cpu.rel()
        #expect(cpu.address == 0x0000 + 6)
        #expect(cpu.programCounter == 0x0000)
    }

    @Test("Absolute Addressing: programCounter wrap at 0xFFFF/0x0000")
    func absoluteProgramCounterWrap() throws {
        let (cpu, bus) = setupCPU()
        bus.write(address: 0xFFFF, data: 0x34) // low
        bus.write(address: 0x0000, data: 0x12) // high
        cpu.programCounter = 0xFFFF
        cpu.abs()
        #expect(cpu.address == 0x1234)
        #expect(cpu.programCounter == 0x0001)
    }

    @Test("Absolute,X Addressing: programCounter wrap at 0xFFFF/0x0000")
    func absoluteXProgramCounterWrap() throws {
        let (cpu, bus) = setupCPU()
        cpu.xRegister = 0x01
        bus.write(address: 0xFFFF, data: 0xFE)
        bus.write(address: 0x0000, data: 0x20)
        cpu.programCounter = 0xFFFF
        cpu.abx()
        #expect(cpu.address == 0x20FE + 1)
        #expect(cpu.programCounter == 0x0001)
    }

    @Test("Absolute,Y Addressing: programCounter wrap at 0xFFFF/0x0000")
    func absoluteYProgramCounterWrap() throws {
        let (cpu, bus) = setupCPU()
        cpu.yRegister = 0x05
        bus.write(address: 0xFFFF, data: 0xF0)
        bus.write(address: 0x0000, data: 0x30)
        cpu.programCounter = 0xFFFF
        cpu.aby()
        #expect(cpu.address == 0x30F0 + 5)
        #expect(cpu.programCounter == 0x0001)
    }

    @Test("Indirect,X Addressing: programCounter wrap at 0xFFFF")
    func indirectXProgramCounterWrap() throws {
        let (cpu, bus) = setupCPU()
        cpu.xRegister = 0x04
        bus.write(address: 0xFFFF, data: 0x10)
        bus.write(address: 0x10, data: 0x00) // dummy read location
        bus.write(address: 0x14, data: 0x78)
        bus.write(address: 0x15, data: 0x56)
        cpu.programCounter = 0xFFFF
        cpu.idx()
        #expect(cpu.programCounter == 0x0000)
    }

    @Test("Indirect,Y Addressing: programCounter wrap at 0xFFFF")
    func indirectYProgramCounterWrap() throws {
        let (cpu, bus) = setupCPU()
        cpu.yRegister = 0x02
        bus.write(address: 0xFFFF, data: 0x20)
        bus.write(address: 0x20, data: 0x00)
        bus.write(address: 0x21, data: 0x40)
        cpu.programCounter = 0xFFFF
        cpu.idy()
        #expect(cpu.programCounter == 0x0000)
    }

    @Test("Indirect Addressing: programCounter wrap at 0xFFFF/0x0000")
    func indirectProgramCounterWrap() throws {
        let (cpu, bus) = setupCPU()
        bus.write(address: 0xFFFF, data: 0x12) // low
        bus.write(address: 0x0000, data: 0x34) // high
        bus.write(address: 0x3412, data: 0x78)
        bus.write(address: 0x3413, data: 0x56)
        cpu.programCounter = 0xFFFF
        cpu.idi()
        #expect(cpu.programCounter == 0x0001)
    }
}
