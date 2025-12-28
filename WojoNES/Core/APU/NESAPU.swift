//
//  NESAPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

class NESAPU: APU {
    // MARK: Properties

    var status: UInt8

    var bus: Bus!

    // MARK: Lifecycle

    init() {
        status = 0
    }

    // MARK: Functions

    func connect(_ bus: Bus) {
        self.bus = bus
    }

    func write(address: Int, value: UInt8) {}

    func step() {
        // APU stepping logic will be implemented later
        // For now, this is a placeholder to match NESik's architecture
    }
}
