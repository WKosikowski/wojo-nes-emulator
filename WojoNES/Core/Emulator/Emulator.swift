//
//  Emulator.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

import Foundation

protocol Emulator: AnyObject {
    func start()
    func pause()
    func reset()
    func save(to url: URL) throws
    func load(from url: URL) throws
    func connect(cartridge: Cartridge)
}
