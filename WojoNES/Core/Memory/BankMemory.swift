//
//  BankMemory.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 23/12/2025.
//

import Foundation

/// A memory structure that supports bank switching for ROM/RAM management.
///
/// Bank switching allows mappers to swap different memory banks in and out of the
/// address space, enabling cartridges to access more memory than the address space allows.
///
/// This is commonly used in NES emulation for:
/// - PRG ROM bank switching (program code)
/// - CHR ROM/RAM bank switching (graphics data)
/// - Nametable mirroring (PPU VRAM configuration)
final class BankMemory {
    // MARK: Properties

    /// Active banks that are currently mapped into the address space.
    /// These are references to entries in `swapBanks`.
    var banks: [[UInt8]] = []

    /// Pool of available banks that can be swapped into the active banks.
    /// Contains the actual memory data.
    var swapBanks: [[UInt8]] = []

    /// Size of each bank in bytes (e.g., 0x400 = 1KB, 0x2000 = 8KB)
    private var bankSize: Int = 0

    // MARK: Computed Properties

    /// Gets or sets the size of each bank.
    ///
    /// When set, automatically rebuilds both `swapBanks` and `banks` arrays
    /// to match the new bank size. This operation:
    var bankSizeValue: Int {
        get { bankSize }
        set {
            guard newValue > 0 else {
                bankSize = 0
                return
            }

            // Flattens existing swap banks into a contiguous array
            let flatData = swapBanks.flatMap { $0 }
            guard !flatData.isEmpty else {
                bankSize = newValue
                return
            }

            bankSize = newValue

            // Splits the array into new banks of the specified size
            let swapBankCount = flatData.count / bankSize
            swapBanks.removeAll()

            for i in 0 ..< swapBankCount {
                let start = i * bankSize
                let end = start + bankSize
                swapBanks.append(Array(flatData[start ..< end]))
            }

            // Rebuild the active banks array to match
            let totalSize = banks.reduce(0) { $0 + $1.count }
            let activeBankCount = totalSize / bankSize
            banks.removeAll()

            for i in 0 ..< activeBankCount {
                banks.append(swapBanks[i % swapBanks.count])
            }
        }
    }

    // MARK: Functions

    // MARK: - Memory Access

    /// Accesses memory using a linear address that's automatically mapped to bank + offset.
    ///
    /// The address is divided by the bank size to determine which bank to access,
    /// and the remainder becomes the offset within that bank.
    ///
    /// - Parameter addr: Linear address in the memory space
    /// - Returns: The byte value at the specified address
    @inline(__always)
    subscript(addr: Int) -> UInt8 {
        get {
            guard bankSize > 0 else { return 0 }
            let bankIndex = addr / bankSize
            let offset = addr % bankSize
            return banks[bankIndex][offset]
        }
        set {
            guard bankSize > 0 else { return }
            let bankIndex = addr / bankSize
            let offset = addr % bankSize
            banks[bankIndex][offset] = newValue
        }
    }

    // MARK: - Bank Switching

    // Swaps an active bank with a bank from the swap pool.
    //
    // This is used by mappers to switch memory banks in response to writes
    // to mapper registers, enabling access to different ROM/RAM sections.
    //
    // - Parameters:
    //   - bankIdx: Index in the `banks` array to replace
    //   - swapBankIdx: Index in the `swapBanks` array to swap in

    @inline(__always)
    func swap(bankIdx: Int, swapBankIdx: Int) {
        guard bankIdx >= 0, bankIdx < banks.count else { return }
        guard !swapBanks.isEmpty else { return }

        // Handle negative indices (e.g., -1 means last bank)
        var adjustedSwapIdx = swapBankIdx
        if adjustedSwapIdx < 0 {
            adjustedSwapIdx += swapBanks.count
        }

        // Wrap to valid range and swap
        banks[bankIdx] = swapBanks[adjustedSwapIdx % swapBanks.count]
    }
}
