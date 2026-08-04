//
//  SeededRandomNumberGenerator.swift
//  delivery-game
//

import Foundation

/// Injectable random source used by gameplay domain services.
nonisolated protocol RandomNumberGenerating {
    /// Returns a random integer in the provided inclusive range.
    mutating func nextInt(in range: ClosedRange<Int>) -> Int
}

extension RandomNumberGenerating {
    /// Returns an inclusive percentage roll in the range 1...100.
    mutating func rollPercent() -> Int {
        nextInt(in: 1 ... 100)
    }
}

/// Deterministic seeded generator for production gameplay simulations.
nonisolated struct SeededRandomNumberGenerator: RandomNumberGenerating, Sendable {
    /// Linear-congruential generator state.
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        precondition(!range.isEmpty, "Random range must not be empty")

        let width = UInt64(range.upperBound - range.lowerBound + 1)
        let value = nextUInt64() % width
        return range.lowerBound + Int(value)
    }

    /// Deterministic pseudo-random sequence using LCG constants.
    private mutating func nextUInt64() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

/// Test helper that returns scripted random values in order.
nonisolated struct FixedSequenceRandomNumberGenerator: RandomNumberGenerating, Sendable {
    private var values: [Int]
    private var index = 0

    init(values: [Int]) {
        self.values = values
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        precondition(index < values.count, "No scripted random value available at index \(index)")
        let value = values[index]
        index += 1
        precondition(range.contains(value), "Scripted random value \(value) is outside \(range)")
        return value
    }
}
