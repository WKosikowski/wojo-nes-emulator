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
        accumulator = UInt8(result & 0xFF)
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
        let value = read(address) &+ 1
        write(address, value)
        resultRegister = value // to set zero and negative flags
    }

    /// Decrement memory
    func dec() {
        let value = read(address) &- 1
        write(address, value)
        resultRegister = value // to set zero and negative flags
    }

    /// Increment X register
    func inx() {
        xRegister &+= 1
    }

    /// Increment Y register
    func iny() {
        yRegister &+= 1
    }

    /// Decrement X register
    func dex() {
        xRegister &-= 1
    }

    /// Decrement Y register
    func dey() {
        yRegister &-= 1
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
        resultRegister = accumulator
    }

    /// Logical shift right
    func lsr() {
        statusRegister.carry = accumulator & 0b0000_0001 != 0
        accumulator >>= 1
        resultRegister = accumulator
    }

    /// Rotate left
    func rol() {
        statusRegister.carry = accumulator & 0b1000_0000 != 0
        accumulator <<= 1
        if statusRegister.carry {
            accumulator |= 0b0000_0001
        }
        resultRegister = accumulator
    }

    /// Rotate right
    func ror() {
        statusRegister.carry = accumulator & 0b0000_0001 != 0
        accumulator >>= 1
        if statusRegister.carry {
            accumulator |= 0b1000_0000
        }
        resultRegister = accumulator
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
    func jsr() {
        programCounter -= 1
        let highByte = UInt8(programCounter >> 8)
        let lowByte = UInt8(programCounter & 0b1111_1111)
        pushToStack(highByte)
        pushToStack(lowByte)
        programCounter = address
    }

    /// Return from subroutine
    func rts() {
        let lowByte = Int(popFromStack())
        let highByte = Int(popFromStack()) << 8
        programCounter = lowByte | highByte
        programCounter += 1
    }

    /// Return from interrupt
    func rti() {
        statusRegister.value = popFromStack()
        let lowByte = Int(popFromStack())
        let highByte = Int(popFromStack()) << 8
        programCounter = lowByte | highByte
    }

    /// Branch on carry clear
    func bcc() {
        if !statusRegister.carry {
            branch()
        }
    }

    /// Branch on carry set
    func bcs() {
        if statusRegister.carry {
            branch()
        }
    }

    /// Branch on equal (zero flag set)
    func beq() {
        if statusRegister.zero {
            branch()
        }
    }

    /// Branch on not equal (zero flag clear)
    func bne() {
        if !statusRegister.zero {
            branch()
        }
    }

    /// Branch on minus (negative flag set)
    func bmi() {
        if statusRegister.negative {
            branch()
        }
    }

    /// Branch on plus (negative flag clear)
    func bpl() {
        if !statusRegister.negative {
            branch()
        }
    }

    /// Branch on overflow clear
    func bvc() {
        if !statusRegister.overflow {
            branch()
        }
    }

    /// Branch on overflow set
    func bvs() {
        if statusRegister.overflow {
            branch()
        }
    }

    /// Stop CPU
    func stp() {}
    /// Force break
    func brk() {
        let pcHigh = UInt8(programCounter >> 8)
        let pcLow = UInt8(programCounter & 0b1111_1111)
        pushToStack(pcHigh)
        pushToStack(pcLow)
        var sr = statusRegister
        sr.break = true
        pushToStack(sr.value)
        statusRegister.irqDisabled = true
        let stLow = read(0xFFFE)
        let stHigh = read(0xFFFF)
        programCounter = Int(stLow) | (Int(stHigh) << 8)
    }

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
    /// slo – ASL + ORA
    /// Shifts memory left (ASL), then ORAs it with A.
    /// Affects flags: N, Z, C.
    /// Syntax: A = A | (M << 1)
    func slo() {
        var memVal = read(address)
        statusRegister.carry = memVal & 0b1000_0000 != 0
        memVal <<= 1
        resultRegister = memVal
        accumulator |= memVal
    }

    /// rla – ROL + AND
    /// Rotates memory left (ROL), then ANDs with A.
    /// Affects flags: N, Z, C.
    /// Syntax: A = A & (ROL(M))
    func rla() {
        var memVal = read(address)
        statusRegister.carry = memVal & 0b1000_0000 != 0
        memVal <<= 1
        if statusRegister.carry {
            memVal |= 0b0000_0001
        }
        accumulator &= memVal
    }

    /// sre – LSR + EOR
    /// Shifts memory right (LSR), then EORs with A.
    /// Affects flags: N, Z, C.
    /// Syntax: A = A ^ (M >> 1)
    func sre() {
        var memVal = read(address)
        statusRegister.carry = memVal & 0b0000_0001 != 0
        memVal >>= 1
        write(address, memVal)
        accumulator ^= memVal
    }

    /// rra – ROR + ADC
    /// Rotates memory right (ROR), then adds it to A (ADC).
    /// Affects flags: N, Z, C, V.
    /// Syntax: A = A + (ROR(M)) + C
    func rra() {
        var memVal = read(address)
        statusRegister.carry = memVal & 0b0000_0001 != 0
        memVal >>= 1
        if statusRegister.carry {
            memVal |= 0b1000_0000
        }
        write(address, memVal)
        resultRegister = memVal
        accumulator += memVal
        accumulator += (statusRegister.carry ? 1 : 0)
    }

    /// sax – Store A & X
    /// Stores A & X to memory.
    /// Syntax: M = A & X
    func sax() {
        let val = accumulator & xRegister
        write(address, val)
    }

    /// ahx – AND + Store High
    /// Stores (A & X) & high-byte of address + 1.
    func ahx() {
        let val = Int(accumulator) & Int(xRegister) & (address >> 8) + 1
        write(address, UInt8(val))
    }

    /// shx – Store X & High Byte
    /// Stores X & (high byte of address + 1) to memory.
    func shx() {
        let val = Int(xRegister) & (address >> 8) + 1
        write(address, UInt8(val))
    }

    /// shy – Store Y & High Byte
    /// Same as shx, but uses Y instead of X.
    func shy() {
        let val = Int(yRegister) & (address >> 8) + 1
        write(address, UInt8(val))
    }

    /// tas – Transfer A & X to SP, then AHX
    /// SP = A & X, then perform similar to AHX.
    /// Syntax: SP = A & X, then store A & X & (high byte of target address + 1)  to memory (similar to ahx).
    func tas() {
        var val = accumulator & xRegister
        stackPointer = val
        val = val & (UInt8(address >> 8) + 1)
        write(address, val)
    }

    /// las – Load ANDed A, SP, Mem
    /// Loads A = X = SP = M & SP.
    /// Syntax: A = X = SP = M & SP
    func las() {
        let val = read(address) & stackPointer
        accumulator = val
        stackPointer = val
        xRegister = val
    }

    /// lax – Load A and X
    /// Loads memory into both A and X.
    /// Syntax: A = X = M
    func lax() {
        let val = read(address)
        accumulator = val
        xRegister = val
    }

    /// dcp – DEC + CMP
    /// Decrements memory, then compares to A.
    /// Flags set as if A - (M - 1)
    /// Syntax: M -= 1, then CMP M
    func dcp() {
        let val = read(address) - 1
        write(address, val)
        cmp(accumulator, val)
        resultRegister = val
    }

    /// isc – INC + SBC
    /// Increments memory, then subtracts from A.
    /// Syntax: M += 1, then A = A - M - (1 - C)
    func isc() {
        let val = read(address) &+ 1
        write(address, val)
        accumulator = accumulator &- val &- (1 &- (statusRegister.carry ? 1 : 0))
    }

    /// alr – AND + LSR
    /// A = A & M, then shift right.
    /// Syntax: A = (A & M) >> 1
    func alr() {
        var val = accumulator & read(address)
        statusRegister.carry = (val & 1) != 0
        accumulator = val >> 1
    }

    /// anc – AND + C
    /// A = A & M, then C = A >> 7
    /// Forces carry to match bit 7 of result.
    func anc() {
        accumulator &= read(address)
        statusRegister.carry = statusRegister.negative // Accumulator Didset() updates statusRegister.negative
    }

    /// arr – AND + ROR
    /// A = A & M, then rotate right.
    /// C: Set to bit 6 of result.
    /// V: Set if bit 6 XOR bit 5 is 1.
    func arr() {
        let val = accumulator & read(address)
        statusRegister.carry = (val & 1) != 0
        accumulator = (val >> 1) | (statusRegister.carry ? 0b1000_0000 : 0)
        statusRegister.carry = accumulator & 0b0100_0000 != 0
        let bit6 = (accumulator & 0b0100_0000) != 0
        let bit5 = (accumulator & 0b0010_0000) != 0
        statusRegister.overflow = bit6 != bit5
    }

    /// axs – A & X -> CMP
    /// Stores A & X - M to X, then CMP with M.
    /// Often used for weird comparisons.
    func axs() {
        let m = read(address)
        let val = accumulator & xRegister - m
        xRegister = val
        cmp(xRegister, m)
    }

    /// A = (A | 0xEE) & X & M
    func xaa() {
        let m = read(address)
        let val = (accumulator | 0xEE) & xRegister & m
        accumulator = val
    }

    /// No operation
    func nop() {}

    private func branch() {
        // TODO: Handle Interruptions, Detect Cross-Page Reading
        programCounter = address
    }
}
