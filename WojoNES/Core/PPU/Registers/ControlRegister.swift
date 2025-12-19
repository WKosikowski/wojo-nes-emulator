//
//  ControlRegister.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 19/12/2025.
//

/// PPU Control Register (0x2000)
///
/// This struct represents the PPU control register which configures nametable
/// selection, VRAM address increment, pattern table selection for sprites and
/// background, sprite size, and NMI behavior. The register is written to by
/// the CPU (via 0x2000) and read indirectly when needed. Bits are packed as
/// follows (bit 7 -> bit 0):
///
/// 7: Generate NMI at VBlank start (enableNMI)
/// 6: unused
/// 5: Sprite size (0: 8x8, 1: 8x16)
/// 4: Background pattern table (0: $0000, 1: $1000)
/// 3: Sprite pattern table (0: $0000, 1: $1000)
/// 2: VRAM address increment per CPU read/write of PPUDATA (0: +1, 1: +32)
/// 1: Name table Y (bit 1 of base nametable) (nameTableY)
/// 0: Name table X (bit 0 of base nametable) (nameTableX)
///
/// Each register field is represented by its bit magnitude and stored as an integer
/// (instead of a `Bool`). This makes direct bit manipulation and packing/unpacking
/// the 8-bit control register value straightforward and efficient.
///
/// Reference: https://www.nesdev.org/wiki/PPU_registers#Control_($2000)
public struct ControlRegister {
    // MARK: Properties

    /// Name table X select (bit 0)
    /// Chooses left/right nametable for horizontal mirroring.
    /// Values: 0 or 1
    public var nameTableX: Int = 0

    /// Name table Y select (bit 1)
    /// Chooses top/bottom nametable for vertical mirroring.
    /// Values: 0 or 1
    public var nameTableY: Int = 0

    /// VRAM address increment (bit 2)
    /// Determines how the PPU internal address increments after a CPU read/write
    /// to PPU data (0 = increment by 1, 1 = increment by 32). Stored as the
    /// actual increment value (1 or 32) for convenience.
    public var increment: Int = 1

    /// Sprite pattern table (bit 3)
    /// Selects the pattern table used for 8x8 sprites (0 -> $0000, 1 -> $1000)
    public var patternSprite: Int = 0

    /// Background pattern table (bit 4)
    /// Selects the pattern table used for background tiles (0 -> $0000, 1 -> $1000)
    public var patternBg: Int = 0

    /// Sprite size (bit 5)
    /// When 0 sprites are 8x8, when 1 sprites are 8x16. Stored as pixel height
    /// (8 or 16) for convenience.
    public var spriteSize: Int = 8

    /// PPU master/slave flag (bit 6)
    /// Unused. Kept for compatibility with register layout.
    public var slaveMode: Bool = false

    /// Enable NMI on VBlank (bit 7)
    /// When set the PPU will generate a Non-Maskable Interrupt (NMI) at the
    /// start of vertical blanking. The CPU can use this to perform VBlank-safe
    /// updates to PPU state (VRAM updates, palette, etc.).
    public var enableNMI: Bool = false

    /// Temporary data latch used for writes/reads (open-bus behavior tracking)
    /// This field is present in the struct for convenience; the real PPU may
    /// expose open-bus values when reading certain registers.
    public var dataLatch: UInt8 = 0

    // MARK: Computed Properties

    /// Packs/unpacks the individual fields into the 8-bit control register
    /// representation. This is used when reading/writing the register as a
    /// single byte. Get returns the packed value; set decodes into fields.
    public var value: Int {
        get {
            var value = 0
            // Bits 0-1: base nametable
            value |= nameTableX & 0x1
            value |= (nameTableY & 0x1) << 1
            // Bit 2: VRAM increment (0 => +1, 1 => +32)
            value |= (increment > 1 ? 1 : 0) << 2
            // Bit 3: Sprite pattern table
            value |= (patternSprite & 0x1) << 3
            // Bit 4: Background pattern table
            value |= (patternBg & 0x1) << 4
            // Bit 5: Sprite size (0 = 8, 1 = 16)
            value |= (spriteSize > 8 ? 1 : 0) << 5
            // Bit 6: PPU master/slave (unused on NES)
            value |= (slaveMode ? 1 : 0) << 6
            // Bit 7: Generate NMI at start of vertical blanking
            value |= (enableNMI ? 1 : 0) << 7
            return value
        }
        set {
            // Unpack bits into individual fields
            nameTableX = newValue & 0x1
            nameTableY = (newValue >> 1) & 0x1
            // Bit 2 -> increment: 0 => 1, 1 => 32
            increment = ((newValue >> 2) & 0x1) != 0 ? 32 : 1
            patternSprite = (newValue >> 3) & 0x1
            patternBg = (newValue >> 4) & 0x1
            // Bit 5 -> sprite size: 0 => 8, 1 => 16
            spriteSize = ((newValue >> 5) & 0x1) != 0 ? 16 : 8
            slaveMode = ((newValue >> 6) & 0x1) != 0
            enableNMI = ((newValue >> 7) & 0x1) != 0
        }
    }
}
