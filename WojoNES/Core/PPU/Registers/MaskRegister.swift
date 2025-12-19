//
//  MaskRegister.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 19/12/2025.
//

/// PPU Mask Register (0x2001)
///
/// Controls what the PPU renders and how colors are emphasized. The bits are
/// laid out (bit 7 -> bit 0):
///
/// 7: Emphasize Blue
/// 6: Emphasize Green
/// 5: Emphasize Red
/// 4: Show sprites
/// 3: Show background
/// 2: Show sprites in leftmost 8 pixels
/// 1: Show background in leftmost 8 pixels
/// 0: Greyscale
///
/// This struct shows each flag as a boolean property and provides a packed
/// value property for reading/writing the full 8-bit register.
public struct MaskRegister {
    /// Internal mask used by the PPU implementation. The emulator toggles this
    /// between 0x3F and 0x30 when greyscale is enabled.
    private(set) var mask: Int = 0x3F

    /// Greyscale rendering (bit 0). When enabled the PPU renders in greyscale.
    public var greyscale: Bool = false {
        didSet {
            mask = greyscale ? 0x30 : 0x3F
        }
    }

    /// Show background in leftmost 8 pixels (bit 1)
    public var renderBackgroundLeft: Bool = false

    /// Show sprites in leftmost 8 pixels (bit 2)
    public var renderSpritesLeft: Bool = false

    /// Show background rendering (bit 3)
    public var renderBackground: Bool = false

    /// Show sprite rendering (bit 4)
    public var renderSprites: Bool = false

    /// Emphasize red (bit 5)
    public var enhanceRed: Bool = false

    /// Emphasize green (bit 6)
    public var enhanceGreen: Bool = false

    /// Emphasize blue (bit 7)
    public var enhanceBlue: Bool = false

    /// Packed 8-bit register value. get assembles the bit flags into a
    /// single integer. set decodes an integer into the individual flags.
    public var value: Int {
        get {
            var value = 0
            if greyscale { value |= 0x01 }
            if renderBackgroundLeft { value |= 0x02 }
            if renderSpritesLeft { value |= 0x04 }
            if renderBackground { value |= 0x08 }
            if renderSprites { value |= 0x10 }
            if enhanceRed { value |= 0x20 }
            if enhanceGreen { value |= 0x40 }
            if enhanceBlue { value |= 0x80 }
            return value
        }
        set {
            greyscale = (newValue & 0x01) != 0
            renderBackgroundLeft = (newValue & 0x02) != 0
            renderSpritesLeft = (newValue & 0x04) != 0
            renderBackground = (newValue & 0x08) != 0
            renderSprites = (newValue & 0x10) != 0
            enhanceRed = (newValue & 0x20) != 0
            enhanceGreen = (newValue & 0x40) != 0
            enhanceBlue = (newValue & 0x80) != 0
        }
    }
}
