//
//  PPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

protocol PPU {
    func connect(_ bus: Bus)
    func step()
    func read(_ address: Int) -> UInt8
    func write(address: Int, value: UInt8)
    func swapNameTable(bankIdx: Int, swapBankIdx: Int)
    func getFrame() -> PixelMatrix

    var frameComplete: Bool { get set }
    var frameBuffer: [UInt32] { get set }
}
