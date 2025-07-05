//
//  APU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

protocol APU: AnyObject {
    func connect(_ bus: Bus)
}
