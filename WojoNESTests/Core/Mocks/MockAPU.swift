//
//  MockAPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//
@testable import WojoNES

class MockAPU: APU {
    // MARK: Properties

    var connectedBus: Bus?

    // MARK: Functions

    func connect(_ bus: any Bus) { connectedBus = bus }
}
