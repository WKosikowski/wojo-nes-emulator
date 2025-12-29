//
//  CPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

protocol CPU: AnyObject {
    func step()
    func setDmaOam(enable: Bool)
    func addNmiInterrupt(_ interrupt: Interrupt)
    func addApuIrqInterrupt(_ interrupt: Interrupt)
    func addDmcIrqInterrupt(_ interrupt: Interrupt)
    func resetCycles()
    func resetProgram()
    func connect(_ bus: Bus)
    var enabled: Bool { get }
    var cycle: Int { get set }
    var nmi: Interrupt! { get }
    var apuIrq: Interrupt! { get }
    var dmcIrq: Interrupt! { get }
    var interrupts: [Interrupt] { get }
}
