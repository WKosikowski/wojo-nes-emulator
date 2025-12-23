//
//  BankMemoryTests.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 23/12/2025.
//

import Testing
@testable import WojoNES

@Suite("BankMemory Tests")
struct BankMemoryTests {
    // MARK: - Initialisation Tests

    @Test("Initialise Empty BankMemory")
    func initialization() {
        let memory = BankMemory()

        #expect(memory.banks.isEmpty, "Banks should be empty initially")
        #expect(memory.swapBanks.isEmpty, "Swap banks should be empty initially")
        #expect(memory.bankSizeValue == 0, "Bank size should be 0 initially")
    }

    // MARK: - Bank Size Tests

    @Test("Set Bank Size")
    func setBankSize() {
        let memory = BankMemory()

        memory.bankSizeValue = 0x400 // 1KB

        #expect(memory.bankSizeValue == 0x400, "Bank size should be 1024 bytes")
    }

    @Test("Set Bank Size Zero")
    func setBankSizeZero() {
        var memory = BankMemory()
        memory.bankSizeValue = 0x400

        // Setting to zero should not change the bank size
        memory.bankSizeValue = 0

        #expect(memory.bankSizeValue == 0, "Bank size should be 0")
    }

    // MARK: - Memory Access Tests

    @Test("Read Memory")
    func readMemory() {
        let memory = BankMemory()

        // Set up a bank with known data
        let testBank = [UInt8](0 ... 255)
        memory.banks.append(testBank)
        memory.bankSizeValue = 256

        // Test reading
        #expect(memory[0] == 0, "First byte should be 0")
        #expect(memory[127] == 127, "Byte at offset 127 should be 127")
        #expect(memory[255] == 255, "Last byte should be 255")
    }

    @Test("Write Memory")
    func writeMemory() {
        let memory = BankMemory()

        // Set up a bank with zeros
        memory.banks.append([UInt8](repeating: 0, count: 256))
        memory.bankSizeValue = 256

        // Write values
        memory[0] = 42
        memory[128] = 99
        memory[255] = 200

        #expect(memory[0] == 42, "Value at 0 should be 42")
        #expect(memory[128] == 99, "Value at 128 should be 99")
        #expect(memory[255] == 200, "Value at 255 should be 200")
    }

    @Test("Multi-Bank Memory Access")
    func multiBankAccess() {
        let memory = BankMemory()

        // Set up two banks
        let bank1 = [UInt8](repeating: 1, count: 256)
        let bank2 = [UInt8](repeating: 2, count: 256)
        memory.banks.append(bank1)
        memory.banks.append(bank2)
        memory.bankSizeValue = 256

        // Access first bank
        #expect(memory[0] == 1, "First byte of bank 1 should be 1")
        #expect(memory[255] == 1, "Last byte of bank 1 should be 1")

        // Access second bank
        #expect(memory[256] == 2, "First byte of bank 2 should be 2")
        #expect(memory[511] == 2, "Last byte of bank 2 should be 2")
    }

    // MARK: - Bank Swapping Tests

//    @Test("Swap Bank")
//    func testSwapBank() {
//        let memory = BankMemory()
//
//        // Set up active bank and swap banks
//        let activeBank = [UInt8](repeating: 10, count: 256)
//        let swapBank1 = [UInt8](repeating: 20, count: 256)
//        let swapBank2 = [UInt8](repeating: 30, count: 256)
//
//        memory.banks.append(activeBank)
//        memory.swapBanks.append(swapBank1)
//        memory.swapBanks.append(swapBank2)
//        memory.bankSizeValue = 256
//
//        // Initially accessing active bank
//        #expect(memory[0] == 10, "Should initially read from active bank")
//
//        // Swap to first swap bank
//        memory.swap(bankIdx: 0, swapBankIdx: 0)
//        #expect(memory[0] == 20, "Should read from swapped bank")
//
//        // Swap to second swap bank
//        memory.swap(bankIdx: 0, swapBankIdx: 1)
//        #expect(memory[0] == 30, "Should read from second swap bank")
//    }

    @Test("Swap Bank with Negative Index")
    func swapBankNegativeIndex() {
        let memory = BankMemory()

        let activeBank = [UInt8](repeating: 10, count: 256)
        let swapBank1 = [UInt8](repeating: 20, count: 256)
        let swapBank2 = [UInt8](repeating: 30, count: 256)

        memory.banks.append(activeBank)
        memory.swapBanks.append(swapBank1)
        memory.swapBanks.append(swapBank2)
        memory.bankSizeValue = 256

        // Swap with negative index (should access last bank)
        memory.swap(bankIdx: 0, swapBankIdx: -1)
        #expect(memory[0] == 30, "Negative index -1 should access last swap bank")

        memory.swap(bankIdx: 0, swapBankIdx: -2)
        #expect(memory[0] == 20, "Negative index -2 should access second to last swap bank")
    }

//    @Test("Swap Bank Out of Bounds")
//    func swapBankOutOfBounds() {
//        let memory = BankMemory()
//
//        let activeBank = [UInt8](repeating: 10, count: 256)
//        let swapBank = [UInt8](repeating: 20, count: 256)
//
//        memory.banks.append(activeBank)
//        memory.swapBanks.append(swapBank)
//        memory.bankSizeValue = 256
//
//        // Try swapping with out of bounds active bank index
//        memory.swap(bankIdx: 5, swapBankIdx: 0)
//
//        // Should remain unchanged
//        #expect(memory[0] == 10, "Invalid bank index should not affect memory")
//    }

    @Test("Swap with Wrapping Index")
    func swapWithWrappingIndex() {
        let memory = BankMemory()

        let activeBank = [UInt8](repeating: 10, count: 256)
        let swapBank1 = [UInt8](repeating: 20, count: 256)
        let swapBank2 = [UInt8](repeating: 30, count: 256)

        memory.banks.append(activeBank)
        memory.swapBanks.append(swapBank1)
        memory.swapBanks.append(swapBank2)
        memory.bankSizeValue = 256

        // Swap with wrapping index (3 % 2 = 1)
        memory.swap(bankIdx: 0, swapBankIdx: 3)
        #expect(memory[0] == 30, "Index 3 should wrap to index 1 (swapBank2)")
    }

    // MARK: - Bank Size Reconfiguration Tests

    @Test("Reconfigure Bank Size")
    func reconfigureBankSize() {
        let memory = BankMemory()

        // Create initial 256-byte bank
        let initialBank = [UInt8](0 ... 255)
        memory.swapBanks.append(initialBank)
        memory.banks.append(initialBank)
        memory.bankSizeValue = 256

        // Reconfigure to 128-byte banks
        memory.bankSizeValue = 128

        #expect(memory.swapBanks.count == 2, "Should split into 2 banks of 128 bytes")
        #expect(memory.banks.count == 2, "Active banks should also split")
        #expect(memory[0] == 0, "First byte of first bank should be 0")
        #expect(memory[128] == 128, "First byte of second bank should be 128")
    }

    @Test("Read from Empty Memory")
    func readFromEmptyMemory() {
        let memory = BankMemory()

        // Reading from empty memory should return 0
        let value = memory[0]
        #expect(value == 0, "Should return 0 from empty memory")
    }

    // MARK: - Edge Case Tests

    @Test("Write and Read Same Address Multiple Times")
    func multipleWrites() {
        let memory = BankMemory()

        memory.banks.append([UInt8](repeating: 0, count: 256))
        memory.bankSizeValue = 256

        // Multiple writes to same address
        memory[42] = 1
        #expect(memory[42] == 1)

        memory[42] = 100
        #expect(memory[42] == 100)

        memory[42] = 255
        #expect(memory[42] == 255)
    }

    @Test("Large Memory Space")
    func largeMemorySpace() {
        let memory = BankMemory()

        // Create 4 banks of 4KB each (16KB total)
        for i in 0 ..< 4 {
            memory.banks.append([UInt8](repeating: UInt8(i), count: 0x1000))
        }
        memory.bankSizeValue = 0x1000

        // Verify each bank
        #expect(memory[0x0000] == 0, "Bank 0 should have value 0")
        #expect(memory[0x1000] == 1, "Bank 1 should have value 1")
        #expect(memory[0x2000] == 2, "Bank 2 should have value 2")
        #expect(memory[0x3000] == 3, "Bank 3 should have value 3")
    }
}
