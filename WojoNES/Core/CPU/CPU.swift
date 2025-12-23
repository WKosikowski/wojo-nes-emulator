//
//  CPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

protocol CPU: AnyObject {
    func step()
    func handleIRQ()
    func handleNMI()
    func setDmaOam(enable: Bool)

    func connect(_ bus: Bus)
    var enabled: Bool { get }
}
