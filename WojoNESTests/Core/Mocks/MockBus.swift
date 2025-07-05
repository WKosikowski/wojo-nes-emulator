//
//  MockBus.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//
@testable import WojoNES

/// Mock implementations for dependencies
class MockBus: Bus {
    // MARK: Properties

    var connectedComponents: [Any] = []

    // MARK: Functions

    func read(address: Int) -> UInt8 {
        1
    }

    func write(address: Int, data: UInt8) {}

    func connect(_ component: any APU) { connectedComponents.append(component) }
    func connect(_ component: any PPU) { connectedComponents.append(component) }
    func connect(_ component: any CPU) { connectedComponents.append(component) }
    func connect(_ component: any Cartridge) { connectedComponents.append(component) }
}
