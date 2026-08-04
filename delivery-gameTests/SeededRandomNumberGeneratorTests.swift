//
//  SeededRandomNumberGeneratorTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct SeededRandomNumberGeneratorTests {

    @Test func sameSeedProducesSameSequence() {
        var lhs = SeededRandomNumberGenerator(seed: 42)
        var rhs = SeededRandomNumberGenerator(seed: 42)

        let lhsValues = (0..<20).map { _ in lhs.nextInt(in: 0 ... 10_000) }
        let rhsValues = (0..<20).map { _ in rhs.nextInt(in: 0 ... 10_000) }

        #expect(lhsValues == rhsValues)
    }

    @Test func differentSeedsProduceDifferentSequencePrefix() {
        var lhs = SeededRandomNumberGenerator(seed: 42)
        var rhs = SeededRandomNumberGenerator(seed: 4_242)

        let lhsValues = (0..<10).map { _ in lhs.nextInt(in: 0 ... 10_000) }
        let rhsValues = (0..<10).map { _ in rhs.nextInt(in: 0 ... 10_000) }

        #expect(lhsValues != rhsValues)
    }

    @Test func scriptedGeneratorReturnsExactValues() {
        var generator = FixedSequenceRandomNumberGenerator(values: [3, 1, 100, 42])

        #expect(generator.nextInt(in: 1 ... 10) == 3)
        #expect(generator.rollPercent() == 1)
        #expect(generator.rollPercent() == 100)
        #expect(generator.nextInt(in: 40 ... 50) == 42)
    }

    @Test func percentRollIsInclusiveFrom1Through100() {
        var lowSeed = SeededRandomNumberGenerator(seed: 1)
        var highSeed = SeededRandomNumberGenerator(seed: 2)

        let lowRolls = (0..<300).map { _ in lowSeed.rollPercent() }
        let highRolls = (0..<300).map { _ in highSeed.rollPercent() }

        #expect(lowRolls.allSatisfy { 1 ... 100 ~= $0 })
        #expect(highRolls.allSatisfy { 1 ... 100 ~= $0 })
    }

    @Test func rangeBoundariesAreInclusiveForAnyRange() {
        var scriptedLow = FixedSequenceRandomNumberGenerator(values: [5])
        var scriptedHigh = FixedSequenceRandomNumberGenerator(values: [9])

        #expect(scriptedLow.nextInt(in: 5 ... 9) == 5)
        #expect(scriptedHigh.nextInt(in: 5 ... 9) == 9)
    }
}
