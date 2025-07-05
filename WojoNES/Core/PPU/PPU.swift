//
//  PPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

protocol PPU: AnyObject {
    func connect(_ bus: Bus)
}
