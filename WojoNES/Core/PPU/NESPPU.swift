//
//  NESPPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

class NESPPU: PPU {
    // MARK: Properties

    var bus: Bus!

    // MARK: Lifecycle

    init() {}

    // MARK: Functions

    func connect(_ bus: Bus) {
        self.bus = bus
    }
}
