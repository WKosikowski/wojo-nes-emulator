//
//  PixelRow.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 23/12/2025.
//

import Foundation

/// Represents a single tile or sprite row, including its pattern data and rendering attributes.
/// Used by the PPU to store tile and sprite information during the rendering pipeline.
public struct PixelRow {
    // MARK: Properties

    /// Tile ID: Index into the pattern table memory to identify which tile to render
    public var id: Int = 0

    /// X coordinate: Horizontal screen position (0-255 for sprites and tiles)
    public var x: Int = 0

    /// Y coordinate: Vertical screen position (0-239 for visible area, -1 for pre-render)
    public var y: Int = 0

    /// Attribute byte: Encodes rendering flags including priority, palette index, and flip bits.
    /// Bit layout: 0x?0PPFHVV where PP = palette (0-3), FH = horizontal flip, VV = vertical flip
    public var attribute: Int = 0

    /// LSB (Low Significance Byte): Bit plane 0 of the pattern data (8 bits representing one row of pixels)
    public var lsb: Int = 0

    /// MSB (High Significance Byte): Bit plane 1 of the pattern data (8 bits representing one row of pixels)
    public var msb: Int = 0

    /// Flag indicating whether this sprite is sprite zero (used for collision detection with background)
    public var isSpriteZero: Bool = false

    // MARK: Computed Properties

    /// Priority flag: Determines whether the sprite/tile renders in front of or behind the background.
    /// Returns true if priority is 0 (in front), false if priority is 1 (behind).
    @inline(__always)
    public var priority: Bool {
        (attribute & 0x20) == 0
    }

    /// Palette index: Extracts the colour palette selection from the attribute byte.
    /// Returns a value of 0x04-0x07 for sprites (uses sprite palette) or 0x00-0x03 for background.
    @inline(__always)
    public var paletteIndex: Int {
        Int(attribute & 0x03) | 0x04
    }

    // MARK: Functions

    /// Retrieves a single pixel value from the pattern data at the specified bit position.
    /// Combines the LSB and MSB to form a 2-bit colour index (0-3) representing one pixel.
    /// - Parameter index: Bit position within the pattern byte (0-7, where 0 is the rightmost pixel).
    /// - Returns: A 2-bit colour value (0-3), where 0 is transparent for sprites.
    @inline(__always)
    public func getPatternPixel(index: Int) -> Int {
        let lo = (lsb >> index) & 1
        let hi = (msb >> index) & 1
        return (hi << 1) | lo
    }
}
