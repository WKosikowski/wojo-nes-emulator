//
//  Emulator.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

protocol Emulator: AnyObject {
    func start()
    func pause()
    func reset()
    func save()
    func load()
    func connect(cartridge: Cartridge)
}
