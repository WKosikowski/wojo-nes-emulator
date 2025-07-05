//
//  NESTestsSupportedTests.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

import Foundation
import Testing
@testable import WojoNES

// MARK: - NESCartridgeTests

@Suite("CPU Tests")
struct NESTestsSupportedTests {
    /// Test loading and validating a valid NES file from the test bundle
    @Test
    func allInstructionsTest() throws {
        let bundle = Bundle(for: A.self)
        guard let url = bundle.url(forResource: "nestest", withExtension: "nes") else {
            throw TestError("Could not find sample.nes in test bundle")
        }

        // Read the NES file data
        let data = try Data(contentsOf: url)
        let cartridge = try #require(try NESCartridge(data: data))

        let cpu = NESCPU()
        let bus = NESBus()

        cpu.connect(bus)
        bus.connect(cartridge)
        bus.connect(cpu)

        cpu.programCounter = 0xC000
        #expect(bus.ram[0x2] == 0x0)
        cpu.step()
        #expect(bus.ram[0x2] == 0x0)
        for i in 0 ... 10_000_000 {
            cpu.step()
            #expect(bus.ram[0x2] == 0x0)
        }

        #expect(bus.ram[0x3] == 0x0)
    }
}
