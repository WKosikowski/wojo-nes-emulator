//
//  MockPPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//
@testable import WojoNES

class MockPPU: PPU {
    // MARK: Properties

    var frameBuffer: [UInt32] = []

    var connectedBus: Bus?

    // MARK: Functions

    func frameReady() -> Bool {
        false
    }

    func step() {}

    func read(_ address: UInt16) -> UInt8 {
        0
    }

    func write(address: UInt16, value: UInt8) {}

    func connect(_ bus: any Bus) { connectedBus = bus }
}
