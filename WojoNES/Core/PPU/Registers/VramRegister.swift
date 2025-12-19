//
//  VramRegister.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 19/12/2025.
//

/// Represents the PPU VRAM Address Register (0x2006), which controls the current
/// memory address for PPU VRAM reads and writes..
///
/// The 15-bit VRAM address encodes:
/// - Fine X (3 bits): Horizontal fine scroll within 8-pixel tile
/// - Coarse X (5 bits): Horizontal nametable coordinate (0-31)
/// - Coarse Y (5 bits): Vertical nametable coordinate (0-29)
/// - NameTable X/Y (1 bit each): Which of 4 nametables (horizontal/vertical mirror)
/// - Fine Y (3 bits): Vertical fine scroll within 8-pixel tile
///
/// The register uses a two-write latch: first write sets high byte, second write sets low byte.
/// This prevents partial writes from corrupting the address.
///
/// Address Layout (15-bit):
/// ```
/// [Fine Y (3)] [NT Y (1)] [NT X (1)] [Coarse Y (5)] [Coarse X (5)]
/// [14-12]      [11]       [10]       [9-5]          [4-0]
/// ```
///
/// Ref: https://www.nesdev.org/wiki/PPU_scrolling
public struct VramRegister {
    // MARK: Properties

    /// A12 Toggle flag - Set when fine Y bit 0 transitions from 0 to 1.
    /// Used to detect pattern table bank switches for sprite rendering.
    public var a12Toggled: Bool

    /// Fine X scroll (3 bits, range 0-7)
    /// Horizontal pixel offset within the current 8-pixel tile block.
    public var fineX: Int

    /// Coarse X coordinate (5 bits, range 0-31)
    /// Horizontal nametable position. Maps to tiles 0-31 on a scanline.
    public var coarseX: Int

    /// Coarse Y coordinate (5 bits, range 0-29)
    /// Vertical nametable position. Maps to rows 0-29 in a nametable.
    public var coarseY: Int

    /// NameTable X select (1 bit: 0 or 1)
    /// Selects between left (0) and right (1) nametables for horizontal mirroring.
    public var nameTableX: Int

    /// NameTable Y select (1 bit: 0 or 1)
    /// Selects between top (0) and bottom (1) nametables for vertical mirroring.
    public var nameTableY: Int

    /// Write latch flag - Toggles after each write to track latch state.
    /// True = next write affects high byte, False = next write affects low byte.
    public var latched: Bool

    /// Fine Y scroll (3 bits, range 0-7) - Private to ensure a12Toggled updates.
    /// Vertical pixel offset within the current 8-pixel tile row.
    private var fineY: Int

    // MARK: Computed Properties

    /// Fine Y scroll value with automatic A12 toggle detection.
    /// When fine Y transitions from 0 to 1 (bit 0), a12Toggled flag is set.
    /// This signals a pattern table bank switch in sprite rendering.
    ///
    /// - Get: Returns current fine Y value (0-7)
    /// - Set: Updates fine Y and checks for 0→1 transition on bit 0
    public var fineYValue: Int {
        get { fineY }
        set {
            // Detect transition: was bit 0 clear, and now is it set?
            a12Toggled = (fineY & 1) == 0 && (newValue & 1) == 1
            fineY = newValue
        }
    }

    /// Complete 15-bit PPU VRAM address packed into a single integer.
    /// Encodes all scroll and nametable components into hardware format.
    ///
    /// - Get: Packs fine Y, nametable, coarse coordinates into address
    /// - Set: Unpacks address bytes into individual coordinate components
    ///
    /// Layout: [Fine Y (3)] [NT Y (1)] [NT X (1)] [Coarse Y (5)] [Coarse X (5)]
    public var address: Int {
        get { (fineY << 12) | (nameTableY << 11) | (nameTableX << 10) | (coarseY << 5) | coarseX }
        set {
            coarseX = newValue & 0x1F // Bits 4-0
            coarseY = (newValue >> 5) & 0x1F // Bits 9-5
            nameTableX = (newValue >> 10) & 0x1 // Bit 10
            nameTableY = (newValue >> 11) & 0x1 // Bit 11
            fineY = (newValue >> 12) & 0x7 // Bits 14-12
        }
    }

    /// Horizontal scroll position (X-axis) combining all horizontal components.
    /// Ranges from 0 to 511 (0-255 for screen, 256-511 for next screen).
    ///
    /// - Get: Combines nametable X, coarse X, and fine X into pixel position
    /// - Set: Distributes pixel position into scroll components
    ///
    /// Formula: (nameTableX * 256) + (coarseX * 8) + fineX
    public var scrollX: Int {
        get { (nameTableX << 8) | (coarseX << 3) | fineX }
        set {
            fineX = newValue & 7 // Last 3 bits: fine X (0-7)
            coarseX = (newValue >> 3) & 0x1F // Next 5 bits: coarse X (0-31)
            nameTableX = (newValue >> 8) & 0x1 // Bit 8: nametable X select
        }
    }

    /// Vertical scroll position (Y-axis) combining all vertical components.
    /// Ranges from 0 to 479 (0-239 for screen, 240-479 for next screen).
    ///
    /// - Get: Combines nametable Y, coarse Y, and fine Y into pixel position
    /// - Set: Distributes pixel position into scroll components
    ///
    /// Formula: (nameTableY * 256) + (coarseY * 8) + fineY
    public var scrollY: Int {
        get { (nameTableY << 8) | (coarseY << 3) | fineY }
        set {
            fineY = newValue & 7 // Last 3 bits: fine Y (0-7)
            coarseY = (newValue >> 3) & 0x1F // Next 5 bits: coarse Y (0-29)
            nameTableY = (newValue >> 8) & 0x1 // Bit 8: nametable Y select
        }
    }

    // MARK: Lifecycle

    /// Initializes a new VRAM register with optional coordinate values.
    ///
    /// - Parameters:
    ///   - a12Toggled: A12 toggle detection flag (default: false)
    ///   - fineX: Horizontal fine scroll 0-7 (default: 0)
    ///   - fineY: Vertical fine scroll 0-7 (default: 0)
    ///   - coarseX: Horizontal nametable coordinate 0-31 (default: 0)
    ///   - coarseY: Vertical nametable coordinate 0-29 (default: 0)
    ///   - nameTableX: Horizontal nametable select 0-1 (default: 0)
    ///   - nameTableY: Vertical nametable select 0-1 (default: 0)
    ///   - latched: Write latch state (default: false)
    public init(
        a12Toggled: Bool = false,
        fineX: Int = 0,
        fineY: Int = 0,
        coarseX: Int = 0,
        coarseY: Int = 0,
        nameTableX: Int = 0,
        nameTableY: Int = 0,
        latched: Bool = false
    ) {
        self.a12Toggled = a12Toggled
        self.fineX = fineX
        self.fineY = fineY
        self.coarseX = coarseX
        self.coarseY = coarseY
        self.nameTableX = nameTableX
        self.nameTableY = nameTableY
        self.latched = latched
    }

    // MARK: Functions

    /// Sets the PPU VRAM address using the two-write latch protocol.
    /// First write sets the high byte (15-8), second write sets the low byte (7-0).
    ///
    /// - Parameter value: 8-bit value written to PPU address register (0x2006)
    public mutating func setAddress(_ value: Int) {
        latched.toggle()
        if latched {
            // First write: load high byte into address (left shift by 8)
            address = value << 8
        } else {
            // Second write: merge low byte into address
            // Preserve high byte, update coarse coordinates from low byte
            coarseX = value & 0x1F // Bits 4-0: coarse X
            coarseY |= (value >> 5) & 0x7 // Bits 7-5: coarse Y lower bits
        }
    }

    /// Sets the scroll position using the two-write latch protocol.
    /// First write sets horizontal scroll (X), second write sets vertical scroll (Y).
    ///
    /// - Parameter value: 8-bit scroll value written to PPU scroll register (0x2005)
    public mutating func setScroll(_ value: Int) {
        latched.toggle()
        if latched {
            // First write: horizontal scroll
            fineX = value & 0x7 // Bits 2-0: fine X (0-7)
            coarseX = value >> 3 // Bits 7-3: coarse X (0-31)
        } else {
            // Second write: vertical scroll
            fineY = value & 0x7 // Bits 2-0: fine Y (0-7)
            coarseY = value >> 3 // Bits 7-3: coarse Y (0-29)
        }
    }
}
