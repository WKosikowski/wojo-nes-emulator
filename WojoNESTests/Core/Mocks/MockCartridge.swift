//
//  MockCartridge.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//
import Foundation
@testable import WojoNES

class MockCartridge: Cartridge {
    func write(data: Data, address: UInt16) {}

    func read(address: UInt16) -> UInt8 {
        1
    }

    func reset() {}
}
