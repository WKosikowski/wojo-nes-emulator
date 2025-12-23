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

    var ram: [Int: UInt8] = [:]

    // MARK: Functions

    func read(address: Int) -> UInt8 {
        if let data = ram[address] {
            return data
        } else {
            fatalError("nothing was written to memory at  \(String(format: "%02x", 12))")
        }
    }

    func write(address: Int, data: UInt8) {
        ram[address] = data
    }

    func connect(_ component: any APU) { connectedComponents.append(component) }
    func connect(_ component: any PPU) { connectedComponents.append(component) }
    func connect(_ component: any CPU) { connectedComponents.append(component) }
    func connect(_ component: any Cartridge) { connectedComponents.append(component) }
}
