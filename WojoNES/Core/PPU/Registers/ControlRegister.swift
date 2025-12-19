//
//  ControlRegister.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 19/12/2025.
//

public struct ControlRegister {
    // MARK: Properties

    public var nameTableX: Int = 0
    public var nameTableY: Int = 0
    public var increment: Int = 1
    public var patternSprite: Int = 0
    public var patternBg: Int = 0
    public var spriteSize: Int = 8
    public var slaveMode: Bool = false
    public var enableNMI: Bool = false
    public var dataLatch: UInt8 = 0

    // MARK: Computed Properties

    public var register: Int {
        get {
            var value = 0
            value |= nameTableX & 0x1
            value |= (nameTableY & 0x1) << 1
            value |= (increment > 1 ? 1 : 0) << 2
            value |= (patternSprite & 0x1) << 3
            value |= (patternBg & 0x1) << 4
            value |= (spriteSize > 8 ? 1 : 0) << 5
            value |= (slaveMode ? 1 : 0) << 6
            value |= (enableNMI ? 1 : 0) << 7
            return value
        }
        set {
            nameTableX = newValue & 0x1
            nameTableY = (newValue >> 1) & 0x1
            increment = ((newValue >> 2) & 0x1) != 0 ? 32 : 1
            patternSprite = (newValue >> 3) & 0x1
            patternBg = (newValue >> 4) & 0x1
            spriteSize = ((newValue >> 5) & 0x1) != 0 ? 16 : 8
            slaveMode = ((newValue >> 6) & 0x1) != 0
            enableNMI = ((newValue >> 7) & 0x1) != 0
        }
    }
}
