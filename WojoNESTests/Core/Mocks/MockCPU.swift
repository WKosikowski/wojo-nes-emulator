//
//  MockCPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//
@testable import WojoNES

class MockCPU: CPU {
    // MARK: Properties

    var connectedBus: Bus?

    var enabled: Bool = false

    // MARK: Functions

    func step() {}

    func handleIRQ() {}

    func handleNMI() {}

    func connect(_ bus: any Bus) { connectedBus = bus }

    func setDmaOam(enable: Bool) {}
}
