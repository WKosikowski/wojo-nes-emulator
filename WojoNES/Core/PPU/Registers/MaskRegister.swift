//
//  MaskRegister.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 19/12/2025.
//

public struct MaskRegister {
    private(set) var mask: Int = 0x3F
    public var greyscale: Bool = false {
        didSet {
            mask = greyscale ? 0x30 : 0x3F
        }
    }

    public var renderBackgroundLeft: Bool = false
    public var renderSpritesLeft: Bool = false
    public var renderBackground: Bool = false
    public var renderSprites: Bool = false
    public var enhanceRed: Bool = false
    public var enhanceGreen: Bool = false
    public var enhanceBlue: Bool = false

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
