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
        accumulator = UInt8(result & 0xFF)  // Mask to 8 bits to prevent overflow
    }

    /// Increment memory
    func inc() {
        var value = read(address)
        write(address, value)  // Dummy write during RMW operation
        value = value &+ 1
        write(address, value)  // Final write
        resultRegister = value // to set zero and negative flags
    }

    /// Decrement memory
    func dec() {
        var value = read(address)
        write(address, value)  // Dummy write during RMW operation
        value = value &- 1
        write(address, value)  // Final write
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
        if address == NESCPU.fakeAccumulatorAddress {
            // Accumulator mode
            statusRegister.carry = accumulator & 0b1000_0000 != 0
            accumulator <<= 1
            resultRegister = accumulator
        } else {
            // Memory mode with intermediate write
            var value = read(address)
            write(address, value)  // Dummy write during RMW
            statusRegister.carry = value & 0b1000_0000 != 0
            value <<= 1
            write(address, value)  // Final write
            resultRegister = value
        }
    }

    /// Logical shift right
    func lsr() {
        if address == NESCPU.fakeAccumulatorAddress {
            // Accumulator mode
            statusRegister.carry = accumulator & 0b0000_0001 != 0
            accumulator >>= 1
            resultRegister = accumulator
        } else {
            // Memory mode with intermediate write
            var value = read(address)
            write(address, value)  // Dummy write during RMW
            statusRegister.carry = value & 0b0000_0001 != 0
            value >>= 1
            write(address, value)  // Final write
            resultRegister = value
        }
    }

    /// Rotate left
    func rol() {
        if address == NESCPU.fakeAccumulatorAddress {
            // Accumulator mode
            let oldCarry = statusRegister.carry
            statusRegister.carry = accumulator & 0b1000_0000 != 0
            accumulator <<= 1
            if oldCarry {
                accumulator |= 0b0000_0001
            }
            resultRegister = accumulator
        } else {
            // Memory mode with intermediate write
            var value = read(address)
            write(address, value)  // Dummy write during RMW
            let oldCarry = statusRegister.carry
            statusRegister.carry = value & 0b1000_0000 != 0
            value <<= 1
            if oldCarry {
                value |= 0b0000_0001
            }
            write(address, value)  // Final write
            resultRegister = value
        }
    }

    /// Rotate right
    func ror() {
        if address == NESCPU.fakeAccumulatorAddress {
            // Accumulator mode
            let oldCarry = statusRegister.carry
            statusRegister.carry = accumulator & 0b0000_0001 != 0
            accumulator >>= 1
            if oldCarry {
                accumulator |= 0b1000_0000
            }
            resultRegister = accumulator
        } else {
            // Memory mode with intermediate write
            var value = read(address)
            write(address, value)  // Dummy write during RMW
            let oldCarry = statusRegister.carry
            statusRegister.carry = value & 0b0000_0001 != 0
            value >>= 1
            if oldCarry {
                value |= 0b1000_0000
            }
            write(address, value)  // Final write
            resultRegister = value
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
    func jsr() {
        // Dummy read from stack (required for accurate cycle timing)
        _ = read(0x100 | Int(stackPointer))
        programCounter -= 1
        pushStack(programCounter >> 8)
        pushStack(programCounter)
        programCounter = address
    }

    /// Return from subroutine
    func rts() {
        // Dummy read from stack before popping (required for accurate cycle timing)
        _ = read(0x100 | Int(stackPointer))
        programCounter = popStack()
        programCounter |= popStack() << 8
        programCounter += 1
        // Dummy read from new PC after incrementing (required for accurate cycle timing)
        _ = read(programCounter)
    }

    /// Return from interrupt
    func rti() {
        // Dummy read from stack before popping (required for accurate cycle timing)
        _ = read(0x100 | Int(stackPointer))
        statusRegister.value = UInt8(popStack())
        statusRegister.break = false  // Clear break flag after pulling status
        programCounter = popStack()
        programCounter |= popStack() << 8
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
        var vectorAddress = address

        // Adjust program counter based on whether this is a software BRK or interrupt
        if statusRegister.break {
            programCounter = programCounter &+ 1
        } else {
            programCounter = programCounter &- 1
        }

        if reset {
            // Reset sequence: fake stack operations (reads but doesn't push)
            reset = false
            _ = popStack()
            stackPointer = stackPointer &- 2
            _ = popStack()
            stackPointer = stackPointer &- 2
            _ = popStack()
            stackPointer = stackPointer &- 2
            vectorAddress = 0xFFFC  // Reset vector
        } else {
            // Normal BRK/IRQ: push PC and status to stack
            pushStack(programCounter >> 8)
            pushStack(programCounter)
            pushStack(Int(statusRegister.value))

            if nmi.isActive {
                nmi.acknowledge()
                vectorAddress = 0xFFFA  // NMI vector
            } else {
                vectorAddress = 0xFFFE  // IRQ/BRK vector
            }
        }

        statusRegister.irqDisabled = true
        programCounter = readWord(vectorAddress)

        // Handle edge case where NMI occurs during BRK
        if nmi.isActive {
            nmi.acknowledge()
            nmi.start(delay: 1)
        }
    }

    // MARK: - Stack Operations

    /// Push accumulator
    func pha() {
        pushToStack(accumulator)
    }

    /// Push processor status
    func php() {
        // Set break flag before pushing (hardware behavior)
        statusRegister.break = true
        // Push status with break flag set (OR with 0x10 ensures bit 4 is set)
        pushStack(Int(statusRegister.value) | 0x10)
    }

    /// Pull accumulator
    func pla() {
        // Dummy read from stack before popping (required for accurate cycle timing)
        _ = read(0x100 | Int(stackPointer))
        accumulator = UInt8(popStack())
    }

    /// Pull processor status
    func plp() {
        // Dummy read from stack before popping (required for accurate cycle timing)
        _ = read(0x100 | Int(stackPointer))
        let oldIrqDisabled = statusRegister.irqDisabled
        statusRegister.value = UInt8(popStack())
        if statusRegister.irqDisabled != oldIrqDisabled {
            statusRegister.irqDisabled = oldIrqDisabled
            statusRegister.toggleIrqDisable = true
        }
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
        if statusRegister.irqDisabled {
            statusRegister.toggleIrqDisable = true
        }
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
        if !statusRegister.irqDisabled {
            statusRegister.toggleIrqDisable = true
        }
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
        statusRegister.zero = (value & accumulator) == 0
        statusRegister.overflow = (value & 0b0100_0000) != 0  // Bit 6 -> V flag
        statusRegister.negative = (value & 0b1000_0000) != 0  // Bit 7 -> N flag
    }

    // MARK: - Undocumented/Illegal Instructions

    /// No operation (double NOP) - reads from address for proper cycle timing
    func dop() {
        _ = read(address)
    }

    /// Triple NOP - reads from address for proper cycle timing
    func top() {
        _ = read(address)
    }
    /// slo – ASL + ORA
    /// Shifts memory left (ASL), then ORAs it with A.
    /// Affects flags: N, Z, C.
    /// Syntax: A = A | (M << 1)
    func slo() {
        var memVal = read(address)
        write(address, memVal)  // Dummy write
        statusRegister.carry = memVal & 0b1000_0000 != 0
        memVal <<= 1
        write(address, memVal)  // Final write
        accumulator |= memVal
        resultRegister = accumulator
    }

    /// rla – ROL + AND
    /// Rotates memory left (ROL), then ANDs with A.
    /// Affects flags: N, Z, C.
    /// Syntax: A = A & (ROL(M))
    func rla() {
        var memVal = read(address)
        write(address, memVal)  // Dummy write
        let oldCarry = statusRegister.carry
        statusRegister.carry = memVal & 0b1000_0000 != 0
        memVal <<= 1
        if oldCarry {
            memVal |= 0b0000_0001
        }
        write(address, memVal)  // Final write
        accumulator &= memVal
        resultRegister = accumulator
    }

    /// sre – LSR + EOR
    /// Shifts memory right (LSR), then EORs with A.
    /// Affects flags: N, Z, C.
    /// Syntax: A = A ^ (M >> 1)
    func sre() {
        var memVal = read(address)
        write(address, memVal)  // Dummy write
        statusRegister.carry = memVal & 0b0000_0001 != 0
        memVal >>= 1
        write(address, memVal)  // Final write
        accumulator ^= memVal
        resultRegister = accumulator
    }

    /// rra – ROR + ADC
    /// Rotates memory right (ROR), then adds it to A (ADC).
    /// Affects flags: N, Z, C, V.
    /// Syntax: A = A + (ROR(M)) + C
    func rra() {
        var memVal = read(address)
        write(address, memVal)  // Dummy write
        let oldCarry = statusRegister.carry
        statusRegister.carry = memVal & 0b0000_0001 != 0
        memVal >>= 1
        if oldCarry {
            memVal |= 0b1000_0000
        }
        write(address, memVal)  // Final write

        // Now perform ADC with the result
        let intAccumulator = Int(accumulator)
        var result = intAccumulator + Int(memVal)
        result += statusRegister.carry ? 1 : 0
        statusRegister.carry = result > 0xFF
        statusRegister.overflow = (result ^ intAccumulator) & (result ^ Int(memVal)) & 0x80 != 0
        accumulator = UInt8(result & 0xFF)
    }

    /// sax – Store A & X
    /// Stores A & X to memory.
    /// Syntax: M = A & X
    func sax() {
        let val = accumulator & xRegister
        write(address, val)
    }

    /// ahx – Store (A & X) & High Byte
    /// Stores (A & X) & high-byte of address + 1.
    func ahx() {
        let val = Int(accumulator) & Int(xRegister) & ((address >> 8) + 1)
        write(address, UInt8(val & 0xFF))
    }

    /// shx – Store X & High Byte
    /// Stores X & (high byte of address + 1) to memory.
    func shx() {
        var addressH = UInt8(address >> 8)
        addressH += 1
        addressH &= xRegister
        let newAddress = (Int(addressH) << 8) | (address & 0xFF)
        write(newAddress, UInt8(addressH))
    }

    /// shy – Store Y & High Byte
    /// Same as shx, but uses Y instead of X.
    func shy() {
        var addressH = UInt8(address >> 8)
        addressH += 1
        addressH &= yRegister
        let newAddress = (Int(addressH) << 8) | (address & 0xFF)
        write(newAddress, UInt8(addressH))
    }

    /// tas – Transfer A & X to SP, then AHX
    /// SP = A & X, then perform similar to AHX.
    /// Syntax: SP = A & X, then store A & X & (high byte of target address + 1)  to memory (similar to ahx).
    func tas() {
        stackPointer = UInt8(accumulator & xRegister)
        let val = Int(stackPointer) & ((address >> 8) + 1)
        write(address, UInt8(val & 0xFF))
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
        var val = read(address)
        write(address, val)  // Dummy write during RMW
        val = val &- 1
        write(address, val)  // Final write
        cmp(accumulator, val)
        resultRegister = val
    }

    /// isc – INC + SBC
    /// Increments memory, then subtracts from A.
    /// Syntax: M += 1, then A = A - M - (1 - C)
    func isc() {
        var val = read(address)
        write(address, val)  // Dummy write during RMW
        val = val &+ 1
        write(address, val)  // Final write

        // Perform SBC with the incremented value
        let memVal = Int(~val)  // Invert for SBC
        let intAccumulator = Int(accumulator)
        var result = intAccumulator + memVal
        result += statusRegister.carry ? 1 : 0
        statusRegister.carry = !(result < 0)
        statusRegister.overflow = (result ^ intAccumulator) & (result ^ memVal) & 0x80 != 0
        accumulator = UInt8(result & 0xFF)
    }

    /// alr – AND + LSR
    /// A = A & M, then shift right.
    /// Syntax: A = (A & M) >> 1
    func alr() {
        accumulator &= read(address)
        statusRegister.carry = (accumulator & 1) != 0
        accumulator >>= 1
    }

    /// anc – AND + C
    /// A = A & M, then C = A >> 7
    /// Forces carry to match bit 7 of result.
    func anc() {
        accumulator &= read(address)
        statusRegister.carry = statusRegister.negative // Accumulator didSet() updates statusRegister.negative
    }

    /// arr – AND + ROR
    /// A = A & M, then rotate right.
    /// C: Set to bit 6 of result.
    /// V: Set if bit 6 XOR bit 5 is 1.
    func arr() {
        var mem = (Int(accumulator) & Int(read(address))) >> 1
        if statusRegister.carry { mem |= 0x80 }
        accumulator = UInt8(mem)
        statusRegister.carry = (accumulator & 0x40) != 0
        statusRegister.overflow = (((accumulator << 1) ^ accumulator) & 0x40) != 0
    }

    /// axs – A & X -> CMP
    /// Stores A & X - M to X, then CMP with M.
    /// Often used for weird comparisons.
    func axs() {
        let m = read(address)
        let result = (Int(accumulator) & Int(xRegister)) - Int(m)
        statusRegister.carry = result >= 0
        xRegister = UInt8(result & 0xFF)
        resultRegister = xRegister
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
        branch(to: address)
    }
}
