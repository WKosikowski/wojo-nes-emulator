//
//  Cartridge.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//
import Foundation

protocol Cartridge: AnyObject {
    func getModel() -> NESModel
    func write(data: Data, address: Int)
    func read(address: Int) -> UInt8
    func reset()

    var mapper: Mapper { get }
    var chrMemory: BankMemory { get }
}
