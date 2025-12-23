//
//  MockCartridge.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//
import Foundation
@testable import WojoNES

class MockCartridge: Cartridge {
    // MARK: Properties

    var mapper = WojoNES.Mapper()

    var chrMemory = WojoNES.BankMemory()

    var tvSystem: TVSystem = .ntsc

    // MARK: Functions

    func getModel() -> WojoNES.NESModel {
        switch tvSystem {
            case .pal:
                return .pal
            default:
                return .ntsc
        }
    }

    func write(data: Data, address: Int) {}

    func read(address: Int) -> UInt8 {
        1
    }

    func reset() {}
}
