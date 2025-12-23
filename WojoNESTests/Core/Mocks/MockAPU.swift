//
//  MockAPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//
@testable import WojoNES

class MockAPU: APU {
    // MARK: Properties

    var status: UInt8 = 0

    var connectedBus: Bus?

    // MARK: Functions

    func write(address: Int, value: UInt8) {}

    func connect(_ bus: any Bus) { connectedBus = bus }
}
