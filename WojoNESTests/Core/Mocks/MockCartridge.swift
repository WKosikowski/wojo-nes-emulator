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

    var mapper = Mapper()

    var chrMemory = BankMemory()

    var prgMemory = BankMemory()

    var tvSystem: TVSystem = .ntsc

    /// Track nametable swaps for testing
    var nameTableSwaps: [(bankIdx: Int, swapBankIdx: Int)] = []

    // MARK: Functions

    func getModel() -> NESModel {
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

    func swapNameTable(bankIdx: Int, swapBankIdx: Int) {
        nameTableSwaps.append((bankIdx: bankIdx, swapBankIdx: swapBankIdx))
    }
}
