//
//  NESCPU+Instructions.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 27/06/2025.
//

public extension NESCPU {
    // MARK: - Arithmetic Instructions

    /// Add with carry
    func adc() {
        let memVal = Int(read(address))
        let intAccumulator = Int(accumulator)
        var result = intAccumulator + memVal
        result += (statusRegister.carry == true) ? 1 : 0
        statusRegister.carry = result > 0xFF
        statusRegister.overflow = (result ^ intAccumulator) & (result ^ memVal) & 0x80 != 0
        accumulator = UInt8(result)
    }

    /// Subtract memory from accumulator with borrow
    /// https://www.nesdev.org/wiki/Instruction_reference#SBC
    func sbc() {
        let memVal = Int(~read(address))
        let intAccumulator = Int(accumulator)
        var result = intAccumulator + memVal
        result += (statusRegister.carry == true) ? 1 : 0
        statusRegister.carry = !(result < 0)
        statusRegister.overflow = (result ^ intAccumulator) & (result ^ memVal) & 0x80 != 0
        accumulator = UInt8(result)
    }

    /// Increment memory
    func inc() {
        let value = read(address) + 1
        write(address, value)
        resultRegister = value // to set zero and negative flags
    }

    /// Decrement memory
    func dec() {
        let value = read(address) - 1
        write(address, value)
        resultRegister = value // to set zero and negative flags
    }

    /// Increment X register
    func inx() {
        xRegister += 1
    }

    /// Increment Y register
    func iny() {
        yRegister += 1
    }

    /// Decrement X register
    func dex() {
        xRegister -= 1
    }

    /// Decrement Y register
    func dey() {
        yRegister -= 1
    }

    // MARK: - Logical Instructions

    /// AND memory with accumulator
    func and() {
        accumulator &= read(address)
    }

    /// OR memory with accumulator
    func ora() {
        accumulator |= read(address)
    }

    /// Exclusive OR memory with accumulator
    func eor() {
        accumulator ^= read(address)
    }

    /// Arithmetic shift left
    func asl() {
        statusRegister.carry = accumulator & 0b1000_0000 != 0
        accumulator <<= 1
    }

    /// Logical shift right
    func lsr() {
        statusRegister.carry = accumulator & 0b0000_0001 != 0
        accumulator >>= 1
    }

    /// Rotate left
    func rol() {
        statusRegister.carry = accumulator & 0b1000_0000 != 0
        accumulator <<= 1
        if statusRegister.carry {
            accumulator |= 0b0000_0001
        }
    }

    /// Rotate right
    func ror() {
        statusRegister.carry = accumulator & 0b0000_0001 != 0
        accumulator >>= 1
        if statusRegister.carry {
            accumulator |= 0b1000_0000
        }
    }

    // MARK: - Data Movement Instructions

    /// Load accumulator
    func lda() {
        accumulator = read(address)
    }

    /// Load X register
    func ldx() {
        xRegister = read(address)
    }

    /// Load Y register
    func ldy() {
        yRegister = read(address)
    }

    /// Store accumulator
    func sta() {
        write(address, accumulator)
    }

    /// Store X register
    func stx() {
        write(address, xRegister)
    }

    /// Store Y register
    func sty() {
        write(address, yRegister)
    }

    /// Transfer accumulator to X register
    func tax() {
        xRegister = accumulator
    }

    /// Transfer Stack Pointer to X register
    func tsx() {
        xRegister = stackPointer
    }

    /// Transfer accumulator to Y register
    func tay() {
        yRegister = accumulator
    }

    /// Transfer X register to accumulator
    func txa() {
        accumulator = xRegister
    }

    /// Transfer Y register to accumulator
    func tya() {
        accumulator = yRegister
    }

    /// Transfer X register to stack pointer
    func txs() {
        stackPointer = xRegister
    }

    // MARK: - Control Flow Instructions

    /// Jump to new location
    func jmp() {
        programCounter = address
    }

    /// Jump to subroutine
    func jsr() {}
    /// Return from subroutine
    func rts() {}
    /// Return from interrupt
    func rti() {}
    /// Branch on carry clear
    func bcc() {}
    /// Branch on carry set
    func bcs() {}
    /// Branch on equal (zero flag set)
    func beq() {}
    /// Branch on not equal (zero flag clear)
    func bne() {}
    /// Branch on minus (negative flag set)
    func bmi() {}
    /// Branch on plus (negative flag clear)
    func bpl() {}
    /// Branch on overflow clear
    func bvc() {}
    /// Branch on overflow set
    func bvs() {}
    /// Stop CPU
    func stp() {}
    /// Force break
    func brk() {}

    // MARK: - Stack Operations

    /// Push accumulator
    func pha() {
        pushToStack(accumulator)
    }

    /// Push processor status
    func php() {
        pushToStack(statusRegister.value)
    }

    /// Pull accumulator
    func pla() {
        accumulator = popFromStack()
    }

    /// Pull processor status
    func plp() {
        statusRegister.value = popFromStack()
    }

    // MARK: - Flag Manipulation Instructions

    /// Clear carry flag
    func clc() {
        statusRegister.carry = false
    }

    /// Clear decimal mode
    func cld() {
        statusRegister.decimal = false
    }

    /// Clear interrupt disable
    func cli() {
        statusRegister.irqDisabled = false
    }

    /// Clear overflow flag
    func clv() {
        statusRegister.overflow = false
    }

    /// Set carry flag
    func sec() {
        statusRegister.carry = true
    }

    /// Set decimal mode
    func sed() {
        statusRegister.decimal = true
    }

    /// Set interrupt disable
    func sei() {
        statusRegister.irqDisabled = true
    }

    // MARK: - Comparison Instructions

    /// Compare memory and accumulator
    func cmp() {
        cmp(accumulator, read(address))
    }

    /// Compare memory and X register
    func cpx() {
        cmp(xRegister, read(address))
    }

    /// Compare memory and Y register
    func cpy() {
        cmp(yRegister, read(address))
    }

    /// Test bits in memory with accumulator
    func bit() {
        let value = read(address)
        statusRegister.zero = value & accumulator == 0
        statusRegister.carry = value & 0b0100_0000 != 0
        statusRegister.negative = value & 0b1000_0000 != 0
    }

    // MARK: - Undocumented/Illegal Instructions

    /// No operation (double NOP)
    func dop() {}
    /// Triple NOP
    func top() {}
    /// Shift left and OR with accumulator
    func slo() {}
    /// Rotate left and AND with accumulator
    func rla() {}
    /// Shift right and exclusive OR with accumulator
    func sre() {}
    /// Rotate right and add to accumulator
    func rra() {}
    /// Store accumulator AND X register
    func sax() {}
    /// AND memory with accumulator, then transfer accumulator to index X
    func ahx() {}
    /// Store X register high byte
    func shx() {}
    /// Store Y register high byte
    func shy() {}
    /// Transfer accumulator and stack pointer
    func tas() {}
    /// Load accumulator and stack pointer
    func las() {}
    /// Load accumulator and X register
    func lax() {}
    /// Decrement memory and compare with accumulator
    func dcp() {}
    /// Increment memory and subtract from accumulator
    func isc() {}
    /// AND immediate with accumulator, then LSR accumulator
    func alr() {}
    /// AND immediate with accumulator, then set carry flag
    func anc() {}
    /// AND immediate with accumulator, then ROR accumulator
    func arr() {}
    /// AND X register with accumulator and store in X
    func axs() {}
    /// Transfer accumulator to X register with AND
    func xaa() {}
    /// No operation
    func nop() {}
}
