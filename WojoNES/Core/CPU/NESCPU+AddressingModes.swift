//
//  NESCPU+AddressingModes.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 27/06/2025.
//

public extension NESCPU {
    /// https://www.nesdev.org/obelisk-6502-guide/addressing.html
    /// Implied addressing: Operates on internal CPU state (e.g., registers) or has no operand.
    /// Accumulator addressing: Specifically targets the accumulator (A register).
    func imp() {
        // Set address to a fake accumulator address, representing the accumulator register.
        address = NESCPU.fakeAccumulatorAddress
    }

    /// Immediate addressing: Uses the next byte after the opcode as the operand value.
    func imm() {
        // Set address to the current program counter (PC), where the immediate value is located.
        address = programCounter
        // Increment PC by 1 to point to the next instruction, wrapping within 16-bit address space (0x0000–0xFFFF).
        programCounter = (programCounter &+ 1) & 0xFFFF
    }

    /// Zero Page addressing: Accesses a memory location in the zero page ($0000–$00FF) using a single-byte address.
    func zpg() {
        // Read the next byte from PC as the zero page address (0x00–0xFF).
        address = Int(read(programCounter))
        // Increment PC by 1, wrapping within 16-bit address space.
        programCounter = (programCounter &+ 1) & 0xFFFF
    }

    /// Zero Page,X addressing: Accesses a zero page address offset by the X register.
    func zpx() {
        // Read the next byte from PC as the base zero page address.
        address = Int(read(programCounter))
        // Increment PC by 1, wrapping within 16-bit address space.
        programCounter = (programCounter &+ 1) & 0xFFFF
        // Add X register to the address, wrapping within zero page (0x00–0xFF).
        address = (address &+ Int(xRegister)) & 0xFF
    }

    /// Zero Page,Y addressing: Accesses a zero page address offset by the Y register.
    func zpy() {
        // Read the next byte from PC as the base zero page address.
        address = Int(read(programCounter))
        // Increment PC by 1, wrapping within 16-bit address space.
        programCounter = (programCounter &+ 1) & 0xFFFF
        // Add Y register to the address, wrapping within zero page (0x00–0xFF).
        address = (address &+ Int(yRegister)) & 0xFF
    }

    /// Relative addressing: Used for branch instructions, computes a target address by adding a signed 8-bit offset to the program counter.
    /// The relative address is computed by adding a signed 8-bit offset to the current program counter.
    func rel() {
        // Step 1: Read the next byte from memory at the current program counter (PC) location.
        // This byte is interpreted as a signed 8-bit offset for a relative jump.
        // - `read(programCounter)` returns a UInt8 (unsigned 8-bit value).
        // - `Int8(bitPattern: ...)` interprets the unsigned byte as a signed 8-bit integer (-128 to +127).
        // - Wrapping it in `Int(...)` promotes the signed 8-bit integer to a full `Int`.
        let offset = Int(Int8(bitPattern: read(programCounter)))

        // Step 2: Increment PC by 1 to point to the next instruction, wrapping within 16-bit address space.
        programCounter = (programCounter &+ 1) & 0xFFFF

        // Step 3: Calculate the target address by adding the signed offset to the incremented PC.
        // - `&+` ensures wrapping addition, mimicking 6502's 16-bit address space behavior.
        // - The result is masked to stay within 0x0000–0xFFFF.
        address = (programCounter &+ offset) & 0xFFFF
    }

    /// Absolute addressing: Uses a 16-bit address specified by two bytes (low, high) after the opcode.
    func abs() {
        // Read the low byte of the 16-bit address from PC.
        let lowByte = read(programCounter)
        // Increment PC by 1.
        programCounter = (programCounter &+ 1) & 0xFFFF
        // Read the high byte of the 16-bit address.
        let highByte = read(programCounter)
        // Increment PC by 1.
        programCounter = (programCounter &+ 1) & 0xFFFF
        // Combine high and low bytes: highByte << 8 forms the upper 8 bits, OR with lowByte for the full 16-bit address.
        address = (Int(highByte) << 8) | Int(lowByte)
    }

    /// Absolute,X addressing: Uses a 16-bit address offset by the X register.
    func abx() {
        // Read the low byte of the 16-bit base address from PC.
        let lowByte = read(programCounter)
        // Increment PC by 1.
        programCounter = (programCounter &+ 1) & 0xFFFF
        // Read the high byte of the base address.
        let highByte = read(programCounter)
        // Increment PC by 1.
        programCounter = (programCounter &+ 1) & 0xFFFF
        // Form the base address (highByte << 8 | lowByte), then add X register.
        // No wrapping is applied, as the result is a 16-bit address (0x0000–0xFFFF).
        address = ((Int(highByte) << 8) | Int(lowByte)) + Int(xRegister)
    }

    /// Absolute,Y addressing: Uses a 16-bit address offset by the Y register.
    func aby() {
        // Read the low byte of the 16-bit base address from PC.
        let lowByte = read(programCounter)
        // Increment PC by 1.
        programCounter = (programCounter &+ 1) & 0xFFFF
        // Read the high byte of the base address.
        let highByte = read(programCounter)
        // Increment PC by 1.
        programCounter = (programCounter &+ 1) & 0xFFFF
        // Form the base address (highByte << 8 | lowByte), then add Y register.
        // No wrapping is applied, as the result is a 16-bit address (0x0000–0xFFFF).
        address = ((Int(highByte) << 8) | Int(lowByte)) + Int(yRegister)
    }

    /// Indirect addressing: Used by JMP instruction, fetches a 16-bit address from a memory location specified by a 16-bit pointer.
    /// Handles the 6502 bug where the high byte is not incremented across page boundaries if the low byte is 0xFF.
    func idi() {
        // Read the low byte of the pointer address from PC.
        let lowByte = Int(read(programCounter))
        // Increment PC by 1.
        programCounter = (programCounter &+ 1) & 0xFFFF
        // Read the high byte of the pointer address.
        let highByte = Int(read(programCounter))
        // Increment PC by 1.
        programCounter = (programCounter &+ 1) & 0xFFFF
        // Form the 16-bit pointer address (highByte << 8 | lowByte).
        let pointer = (highByte << 8) | lowByte
        // Check for the 6502 indirect addressing bug: if low byte is 0xFF, the high byte is read from the same page.
        if lowByte == 0xFF {
            // Read low byte from pointer, high byte from pointer & 0xFF00 (same page).
            address = (Int(read(pointer & 0xFF00)) << 8) | Int(read(pointer))
        } else {
            // Normal case: read low byte from pointer, high byte from pointer + 1.
            address = (Int(read(pointer + 1)) << 8) | Int(read(pointer))
        }
    }

    /// Indirect,X addressing (Indexed Indirect): Uses a zero page address offset by X to fetch a 16-bit address.
    func idx() {
        // Read the zero page address from PC.
        let zPAddress = read(programCounter)
        // Increment PC by 1.
        programCounter = (programCounter &+ 1) & 0xFFFF
        // Add X register to the zero page address, wrapping within zero page (0x00–0xFF).
        let pointer = Int((zPAddress &+ xRegister) & 0xFF)
        // Read the low byte of the target address from the pointer.
        let lowByte = Int(read(pointer))
        // Read the high byte from the next zero page address, wrapping within zero page.
        let highByte = Int(read((pointer + 1) & 0xFF))
        // Form the 16-bit target address (highByte << 8 | lowByte).
        address = (highByte << 8) | lowByte
    }

    /// Indirect,Y addressing (Indirect Indexed): Fetches a 16-bit address from a zero page location, then offsets it by Y.
    func idy() {
        // Read the zero page address from PC.
        let zPAddress = Int(read(programCounter))
        // Increment PC by 1.
        programCounter = (programCounter &+ 1) & 0xFFFF
        // Read the low byte of the base address from the zero page address.
        let lowByte = Int(read(zPAddress))
        // Read the high byte from the next zero page address, wrapping within zero page.
        let highByte = Int(read((zPAddress + 1) & 0xFF))
        // Form the base address (highByte << 8 | lowByte), then add Y register.
        // No wrapping is applied, as the result is a 16-bit address (0x0000–0xFFFF).
        address = ((highByte << 8) | lowByte) + Int(yRegister)
    }
}
