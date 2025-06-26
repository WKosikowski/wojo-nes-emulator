//
//  Instructions.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 26/06/2025.
//

public enum Instruction: CaseIterable {
    // MARK: - Arithmetic Instructions

    /// Add with carry
    case adc
    /// Subtract memory from accumulator with borrow
    case sbc
    /// Increment memory
    case inc
    /// Decrement memory
    case dec
    /// Increment X register
    case inx
    /// Increment Y register
    case iny
    /// Decrement X register
    case dex
    /// Decrement Y register
    case dey

    // MARK: - Logical Instructions

    /// AND memory with accumulator
    case and
    /// OR memory with accumulator
    case ora
    /// Exclusive OR memory with accumulator
    case eor
    /// Arithmetic shift left
    case asl
    /// Logical shift right
    case lsr
    /// Rotate left
    case rol
    /// Rotate right
    case ror

    // MARK: - Data Movement Instructions

    /// Load accumulator
    case lda
    /// Load X register
    case ldx
    /// Load Y register
    case ldy
    /// Store accumulator
    case sta
    /// Store X register
    case stx
    /// Store Y register
    case sty
    /// Transfer accumulator to X register
    case tax
    /// Transfer accumulator to Y register
    case tay
    /// Transfer X register to accumulator
    case txa
    /// Transfer Y register to accumulator
    case tya
    /// Transfer X register to stack pointer
    case txs

    // MARK: - Control Flow Instructions

    /// Jump to new location
    case jmp
    /// Jump to subroutine
    case jsr
    /// Return from subroutine
    case rts
    /// Return from interrupt
    case rti
    /// Branch on carry clear
    case bcc
    /// Branch on carry set
    case bcs
    /// Branch on equal (zero flag set)
    case beq
    /// Branch on not equal (zero flag clear)
    case bne
    /// Branch on minus (negative flag set)
    case bmi
    /// Branch on plus (negative flag clear)
    case bpl
    /// Branch on overflow clear
    case bvc
    /// Branch on overflow set
    case bvs
    /// Force break
    case brk

    // MARK: - Stack Operations

    /// Push accumulator
    case pha
    /// Push processor status
    case php
    /// Pull accumulator
    case pla
    /// Pull processor status
    case plp

    // MARK: - Flag Manipulation Instructions

    /// Clear carry flag
    case clc
    /// Clear decimal mode
    case cld
    /// Clear interrupt disable
    case cli
    /// Clear overflow flag
    case clv
    /// Set carry flag
    case sec
    /// Set decimal mode
    case sed
    /// Set interrupt disable
    case sei

    // MARK: - Comparison Instructions

    /// Compare memory and accumulator
    case cmp
    /// Compare memory and X register
    case cpx
    /// Compare memory and Y register
    case cpy
    /// Test bits in memory with accumulator
    case bit

    // MARK: - Undocumented/Illegal Instructions

    /// No operation (double NOP)
    case dop
    /// Triple NOP
    case top
    /// Shift left and OR with accumulator
    case slo
    /// Rotate left and AND with accumulator
    case rla
    /// Shift right and exclusive OR with accumulator
    case sre
    /// Rotate right and add to accumulator
    case rra
    /// Store accumulator AND X register
    case sax
    /// AND memory with accumulator, then transfer accumulator to index X
    case ahx
    /// Store X register high byte
    case shx
    /// Store Y register high byte
    case shy
    /// Transfer accumulator and stack pointer
    case tas
    /// Load accumulator and stack pointer
    case las
    /// Load accumulator and X register
    case lax
    /// Decrement memory and compare with accumulator
    case dcp
    /// Increment memory and subtract from accumulator
    case isc
    /// AND immediate with accumulator, then LSR accumulator
    case alr
    /// AND immediate with accumulator, then set carry flag
    case anc
    /// AND immediate with accumulator, then ROR accumulator
    case arr
    /// AND X register with accumulator and store in X
    case axs
    /// Transfer accumulator to X register with AND
    case xaa
    /// No operation
    case nop
}
