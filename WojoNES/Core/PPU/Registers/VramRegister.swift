//
//  VramRegister.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 19/12/2025.
//

public struct VramRegister {
    // MARK: Properties

    public var a12Toggled: Bool
    public var fineX: Int
    public var coarseX: Int
    public var coarseY: Int
    public var nameTableX: Int
    public var nameTableY: Int
    public var latched: Bool

    private var fineY: Int

    // MARK: Computed Properties

    public var fineYValue: Int {
        get { fineY }
        set {
            a12Toggled = (fineY & 1) == 0 && (newValue & 1) == 1
            fineY = newValue
        }
    }

    public var address: Int {
        get { (fineY << 12) | (nameTableY << 11) | (nameTableX << 10) | (coarseY << 5) | coarseX }
        set {
            coarseX = newValue & 0x1F
            coarseY = (newValue >> 5) & 0x1F
            nameTableX = (newValue >> 10) & 0x1
            nameTableY = (newValue >> 11) & 0x1
            fineY = (newValue >> 12) & 0x7
        }
    }

    public var scrollX: Int {
        get { (nameTableX << 8) | (coarseX << 3) | fineX }
        set {
            fineX = newValue & 7
            coarseX = (newValue >> 3) & 0x1F
            nameTableX = (newValue >> 8) & 0x1
        }
    }

    public var scrollY: Int {
        get { (nameTableY << 8) | (coarseY << 3) | fineY }
        set {
            fineY = newValue & 7
            coarseY = (newValue >> 3) & 0x1F
            nameTableY = (newValue >> 8) & 0x1
        }
    }

    // MARK: Lifecycle

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

    public mutating func setAddress(_ value: Int) {
        latched.toggle()
        if latched {
            address = value << 8
        } else {
            coarseX = value & 0x1F
            coarseY |= (value >> 5) & 0x7
        }
    }

    public mutating func setScroll(_ value: Int) {
        latched.toggle()
        if latched {
            fineX = value & 0x7
            coarseX = value >> 3
        } else {
            fineY = value & 0x7
            coarseY = value >> 3
        }
    }
}
