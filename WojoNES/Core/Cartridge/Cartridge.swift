//
//  Cartridge.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//
import Foundation

protocol Cartridge: AnyObject {
    func getModel() -> NESModel
    func reset()
    func swapNameTable(bankIdx: Int, swapBankIdx: Int)

    var mapper: Mapper { get }
    var chrMemory: BankMemory { get }
    var prgMemory: BankMemory { get }
    var wRam: [UInt8] { get set }
    var tvSystem: TVSystem { get }
}
