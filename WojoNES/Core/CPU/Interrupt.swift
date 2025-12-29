//
//  Interrupt.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 27/12/2025.
//

class Interrupt {
    // MARK: Properties

    unowned var cpu: CPU! // Immutable reference to CPU
    var enabled: Bool
    var delay: Int = 1
    var cycle: Int

    // MARK: Computed Properties

    /// Computed property for Eta
    var eta: Int {
        cpu.cycle - cycle - delay
    }

    /// Computed property for isActive
    var isActive: Bool {
        enabled && eta >= 0
    }

    /// Computed property for isActivating
    var isActivating: Bool {
        enabled && eta == 0
    }

    // MARK: Lifecycle

    /// Initializer
    init() {
        enabled = false // Default value since not initialized in C#
        cycle = 0 // Default value since not initialized in C#
    }

    // MARK: Functions

    // Method to delay activation

    func delayActivating() {
        if isActivating {
            delay += 1
        }
    }

    // Method to start the interrupt

    func start(delay: Int = 1) {
        if !enabled {
            enabled = true
            cycle = cpu.cycle
            self.delay = delay
        }
    }

    // Method to acknowledge the interrupt

    func acknowledge() {
        enabled = false
        delay = 1
    }

    func setCPU(_ cpu: CPU) {
        self.cpu = cpu
        print("interrupt ", self)
    }

    func resetCycles() {
        cycle = 0
    }
}
