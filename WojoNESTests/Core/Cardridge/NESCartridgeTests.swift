//
//  NESCartridgeTests.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 02/07/2025.
//

import Foundation
import Testing
@testable import WojoNES

// MARK: - A

class A {}

// MARK: - NESCartridgeTests

@Suite("NESCartridge Tests")
struct NESCartridgeTests {
    /// Test loading and validating a valid NES file from the test bundle
    @Test("Validate Sample NES File")
    func validNESFile() async throws {
    }

    /// Test error handling for invalid magic number
    @Test("Invalid Magic Number")
    func testInvalidMagicNumber() async throws {
    }

    /// Test error handling for insufficient data
    @Test("Insufficient Data")
    func insufficientData() async throws {
    }

    /// Test error handling for invalid PRG ROM size
    @Test("Invalid PRG ROM Size")
    func testInvalidPRGROMSize() async throws {
}

// MARK: - TestError

/// Helper error for test setup issues
struct TestError: Error {
    // MARK: Properties

    let message: String

    // MARK: Lifecycle

    init(_ message: String) { self.message = message }
}
