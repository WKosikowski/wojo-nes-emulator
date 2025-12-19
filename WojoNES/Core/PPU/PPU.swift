//
//  PPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

protocol PPU: AnyObject {
    func connect(_ bus: Bus)
    func frameReady() -> Bool
    func step()
    func read(_ address: UInt16) -> UInt8
    func write(address: UInt16, value: UInt8)

    var frameBuffer: [UInt32]
}
