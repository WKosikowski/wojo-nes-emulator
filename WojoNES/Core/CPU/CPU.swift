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

    func connect(_ bus: Bus)
}
