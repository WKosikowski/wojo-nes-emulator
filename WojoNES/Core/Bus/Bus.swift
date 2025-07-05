//
//  Bus.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

protocol Bus {
    func read(address: Int) -> UInt8
    func write(address: Int, data: UInt8)
    func connect(_ ppu: PPU)
    func connect(_ apu: APU)
    func connect(_ cpu: CPU)
    func connect(_ cartridge: Cartridge)
}
