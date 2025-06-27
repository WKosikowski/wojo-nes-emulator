//
//  NESCPU+Instructions.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 27/06/2025.
//

public extension NESCPU {
    // MARK: - Arithmetic Instructions

    /// Add with carry
    func adc() {}
    /// Subtract memory from accumulator with borrow
    func sbc() {}
    /// Increment memory
    func inc() {}
    /// Decrement memory
    func dec() {}
    /// Increment X register
    func inx() {}
    /// Increment Y register
    func iny() {}
    /// Decrement X register
    func dex() {}
    /// Decrement Y register
    func dey() {}

    // MARK: - Logical Instructions

    /// AND memory with accumulator
    func and() {}
    /// OR memory with accumulator
    func ora() {}
    /// Exclusive OR memory with accumulator
    func eor() {}
    /// Arithmetic shift left
    func asl() {}
    /// Logical shift right
    func lsr() {}
    /// Rotate left
    func rol() {}
    /// Rotate right
    func ror() {}

    // MARK: - Data Movement Instructions

    /// Load accumulator
    func lda() {}
    /// Load X register
    func ldx() {}
    /// Load Y register
    func ldy() {}
    /// Store accumulator
    func sta() {}
    /// Store X register
    func stx() {}
    /// Store Y register
    func sty() {}
    /// Transfer accumulator to X register
    func tax() {}
    /// Transfer Stack Pointer to X register
    func tsx() {}
    /// Transfer accumulator to Y register
    func tay() {}
    /// Transfer X register to accumulator
    func txa() {}
    /// Transfer Y register to accumulator
    func tya() {}
    /// Transfer X register to stack pointer
    func txs() {}

    // MARK: - Control Flow Instructions

    /// Jump to new location
    func jmp() {}
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
    func pha() {}
    /// Push processor status
    func php() {}
    /// Pull accumulator
    func pla() {}
    /// Pull processor status
    func plp() {}

    // MARK: - Flag Manipulation Instructions

    /// Clear carry flag
    func clc() {}
    /// Clear decimal mode
    func cld() {}
    /// Clear interrupt disable
    func cli() {}
    /// Clear overflow flag
    func clv() {}
    /// Set carry flag
    func sec() {}
    /// Set decimal mode
    func sed() {}
    /// Set interrupt disable
    func sei() {}

    // MARK: - Comparison Instructions

    /// Compare memory and accumulator
    func cmp() {}
    /// Compare memory and X register
    func cpx() {}
    /// Compare memory and Y register
    func cpy() {}
    /// Test bits in memory with accumulator
    func bit() {}

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
