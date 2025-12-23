//
//  PPUStatusRegister.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 19/12/2025.
//

/// Represents the PPU Status Register (0x2002), read-only register that reports
/// rendering status and sprite collision information.
///
/// PPU Status Register Layout (Bit 7-5):
/// - Bit 7 (0x80): Vertical Blank (V-Blank) flag - set during vertical blanking period
/// - Bit 6 (0x40): Sprite 0 Hit flag - set when sprite 0 pixel overlaps background pixel
/// - Bit 5 (0x20): Sprite Overflow flag - set when more than 8 sprites on a scanline
/// - Bits 4-0: Open bus (return last written PPU register value)
///
/// Reference: https://www.nesdev.org/wiki/PPU_registers#Status_($2002)
struct PPUStatusRegister {
    // MARK: Properties

    /// Sprite Overflow flag (bit 5)
    /// Set when more than 8 sprites are present on the current scanline.
    /// This is used for sprite flickering detection in games.
    var spriteOverflow: Bool = false

    /// Sprite 0 Hit flag (bit 6)
    /// Set when a non-zero pixel of sprite 0 overlaps with a non-transparent pixel
    /// of the background. Used by games to detect background collisions and timing.
    var spriteZeroHit: Bool = false

    /// Vertical Blank (V-Blank) flag (bit 7)
    /// Set during the vertical blanking interval when the PPU is not rendering.
    /// Cleared after a frame is rendered. Signals CPU that it's safe to update
    /// PPU registers and VRAM without causing visual glitches.
    var verticalBlank: Bool = false

    // MARK: Computed Properties

    /// Converts individual flag booleans to their packed register byte value.
    var value: Int {
        get {
            var result = 0
            // Bits 0-4 are open bus (not stored in this register)
            if spriteOverflow { result |= 0x20 } // Set bit 5 (0x20)
            if spriteZeroHit { result |= 0x40 } // Set bit 6 (0x40)
            if verticalBlank { result |= 0x80 } // Set bit 7 (0x80)
            return result
        }
        set {
            // Extract individual flags from packed byte using bitmasks
            spriteOverflow = (newValue & 0x20) != 0 // Check bit 5
            spriteZeroHit = (newValue & 0x40) != 0 // Check bit 6
            verticalBlank = (newValue & 0x80) != 0 // Check bit 7
        }
    }
}
