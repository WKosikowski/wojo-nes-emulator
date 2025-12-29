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

    var cycle: Int = 0

    var nmi: Interrupt!

    var apuIrq: Interrupt!

    var dmcIrq: Interrupt!

    var interrupts: [Interrupt] = []

    // MARK: Functions

    func step() {}

    func handleIRQ() {}

    func handleNMI() {}

    func resetProgram() {}

    func connect(_ bus: any Bus) { connectedBus = bus }

    func setDmaOam(enable: Bool) {}

    func addNmiInterrupt(_ interrupt: WojoNES.Interrupt) {
        nmi = interrupt
        nmi.setCPU(self)
        interrupts.append(nmi)
    }

    func addApuIrqInterrupt(_ interrupt: WojoNES.Interrupt) {
        apuIrq = interrupt
        apuIrq.setCPU(self)
        interrupts.append(apuIrq)
    }

    func addDmcIrqInterrupt(_ interrupt: WojoNES.Interrupt) {
        dmcIrq = interrupt
        dmcIrq.setCPU(self)
        interrupts.append(dmcIrq)
    }

    func resetCycles() {
        cycle = 0
    }
}
