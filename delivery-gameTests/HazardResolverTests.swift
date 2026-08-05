//
//  HazardResolverTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct HazardResolverTests {

    @Test func inclusiveThresholdSucceedsAtBoundaryAndFailsJustAbove() {
        #expect(HazardResolver.succeeds(roll: 1, chancePercent: 1))
        #expect(HazardResolver.succeeds(roll: 50, chancePercent: 50))
        #expect(HazardResolver.succeeds(roll: 51, chancePercent: 50) == false)
        #expect(HazardResolver.succeeds(roll: 15, chancePercent: 15))
        #expect(HazardResolver.succeeds(roll: 16, chancePercent: 15) == false)
        #expect(HazardResolver.succeeds(roll: 100, chancePercent: 100))
        #expect(HazardResolver.succeeds(roll: 1, chancePercent: 0) == false)
        #expect(HazardResolver.succeeds(roll: 100, chancePercent: 99) == false)
    }

    @Test func delayMissConsumesOnlyOneRollAndNeverDamages() {
        // 51 fails the 50% delay check; 1 would succeed damage if incorrectly rolled.
        var rng = FixedSequenceRandomNumberGenerator(values: [51, 1])

        let result = HazardResolver.resolveHeavyTraffic(rng: &rng)

        #expect(result.outcome == .noHazard)
        #expect(result.delayRoll == 51)
        #expect(result.damageRoll == nil)
        #expect(result.rollsConsumed == 1)
        // Unused scripted damage roll remains available.
        #expect(rng.rollPercent() == 1)
    }

    @Test func delayHitAtThresholdThenDamageMiss() {
        var rng = FixedSequenceRandomNumberGenerator(values: [50, 16])

        let result = HazardResolver.resolveHeavyTraffic(rng: &rng)

        #expect(result.outcome == .delayedOnly)
        #expect(result.delayRoll == 50)
        #expect(result.damageRoll == 16)
        #expect(result.rollsConsumed == 2)
    }

    @Test func delayHitThenDamageHitAtThreshold() {
        var rng = FixedSequenceRandomNumberGenerator(values: [1, 15])

        let result = HazardResolver.resolveHeavyTraffic(rng: &rng)

        #expect(result.outcome == .delayedAndDamaged)
        #expect(result.delayRoll == 1)
        #expect(result.damageRoll == 15)
        #expect(result.rollsConsumed == 2)
    }

    @Test func guaranteedDelayAndDamageWithChance100() {
        var rng = FixedSequenceRandomNumberGenerator(values: [100, 100])
        let rule = CardRuleDefinition(
            type: .heavyTraffic,
            baseTravelTimeMinutes: 1,
            delayMinutes: 2,
            delayProbabilityPercent: 100,
            conditionalDamageProbabilityPercent: 100
        )

        let result = HazardResolver.resolveHeavyTraffic(rule: rule, rng: &rng)

        #expect(result.outcome == .delayedAndDamaged)
        #expect(result.rollsConsumed == 2)
    }

    @Test func identicalSeedsProduceIdenticalHazardResults() {
        var first = SeededRandomNumberGenerator(seed: 9_001)
        var second = SeededRandomNumberGenerator(seed: 9_001)

        let firstResults = (0..<12).map { _ in
            HazardResolver.resolveHeavyTraffic(rng: &first)
        }
        let secondResults = (0..<12).map { _ in
            HazardResolver.resolveHeavyTraffic(rng: &second)
        }

        #expect(firstResults == secondResults)
    }

    @Test func differentSeedsCanDiverge() {
        var first = SeededRandomNumberGenerator(seed: 1)
        var second = SeededRandomNumberGenerator(seed: 2)

        let firstResults = (0..<8).map { _ in
            HazardResolver.resolveHeavyTraffic(rng: &first).outcome
        }
        let secondResults = (0..<8).map { _ in
            HazardResolver.resolveHeavyTraffic(rng: &second).outcome
        }

        #expect(firstResults != secondResults)
    }

    @Test func executionEngineUsesSeededHazardRollsDeterministically() throws {
        let input = try makeHeavyTrafficInput()

        var first = ExecutionEngine(input: input, seed: 42)
        _ = first.start()
        guard case .completed(let firstState) = first.runToCompletion() else {
            Issue.record("Expected first seeded run to complete")
            return
        }

        var second = ExecutionEngine(input: input, seed: 42)
        _ = second.start()
        guard case .completed(let secondState) = second.runToCompletion() else {
            Issue.record("Expected second seeded run to complete")
            return
        }

        #expect(firstState.elapsedMinutes == secondState.elapsedMinutes)
        #expect(firstState.damageEventCount == secondState.damageEventCount)
        #expect(firstState.resolvedSteps.map(\.didDelay) == secondState.resolvedSteps.map(\.didDelay))
        #expect(firstState.resolvedSteps.map(\.didDamage) == secondState.resolvedSteps.map(\.didDamage))
    }

    @Test func executionEngineScriptedSequenceCanForceDelayWithoutDamage() throws {
        let input = try makeHeavyTrafficInput()
        // Delay succeeds (50), damage fails (16) for the single Heavy Traffic card.
        var engine = ExecutionEngine(input: input, scriptedRolls: [50, 16])
        _ = engine.start()
        guard case .completed(let state) = engine.runToCompletion() else {
            Issue.record("Expected completion")
            return
        }
        #expect(state.resolvedSteps.first?.didDelay == true)
        #expect(state.resolvedSteps.first?.didDamage == false)
        #expect(state.damageEventCount == 0)
        #expect(state.elapsedMinutes == 10) // heavy 1+2 + seven clear 7
    }

    @Test func executionEngineMissedDelayDoesNotConsumeDamageRoll() throws {
        let input = try makeHeavyTrafficInput()
        // Two Heavy Traffic cards: first delay misses (51); second delay hits (50) then damage hits (1).
        // If the miss incorrectly consumed a damage roll, the second card would see 50 then fail.
        let pathTypes: [CardType] = [
            .heavyTraffic,
            .heavyTraffic,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
        ]
        let dualInput = try makeHeavyTrafficInput(cardTypes: pathTypes)
        var engine = ExecutionEngine(input: dualInput, scriptedRolls: [51, 50, 1])
        _ = engine.start()
        guard case .completed(let state) = engine.runToCompletion() else {
            Issue.record("Expected completion")
            return
        }

        #expect(state.resolvedSteps[0].didDelay == false)
        #expect(state.resolvedSteps[0].didDamage == false)
        #expect(state.resolvedSteps[1].didDelay == true)
        #expect(state.resolvedSteps[1].didDamage == true)
        #expect(state.damageEventCount == 1)
    }

    private func makeHeavyTrafficInput(
        cardTypes overrideTypes: [CardType]? = nil
    ) throws -> ExecutionInput {
        let job = try SeededJobCatalogue.loadDefault()
        let path: [GridCoordinate] = [
            GridCoordinate(row: 0, column: 1),
            GridCoordinate(row: 0, column: 2),
            GridCoordinate(row: 0, column: 3),
            GridCoordinate(row: 0, column: 4),
            GridCoordinate(row: 1, column: 4),
            GridCoordinate(row: 2, column: 4),
            GridCoordinate(row: 3, column: 4),
            .destination,
        ]
        let cardTypes: [CardType] = overrideTypes ?? [
            .heavyTraffic,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
        ]

        var cells = GridCoordinate.allInRowMajorOrder.map {
            GridCell(coordinate: $0, cardType: .clearRoad)
        }
        for (coordinate, cardType) in zip(path, cardTypes) {
            if let index = cells.firstIndex(where: { $0.coordinate == coordinate }) {
                cells[index] = GridCell(coordinate: coordinate, cardType: cardType)
            }
        }
        let grid = try DeliveryGrid(cells: cells)

        var builder = RouteBuilder()
        for coordinate in path {
            let result = builder.select(coordinate)
            guard case .accepted = result else {
                Issue.record("Expected path step \(coordinate) to be accepted")
                break
            }
        }

        let confirmation = RouteConfirmer.confirm(
            route: builder.route,
            job: job,
            grid: grid,
            alreadyConfirmed: false
        )
        guard case .confirmed(let input) = confirmation else {
            Issue.record("Expected route confirmation to succeed")
            return ExecutionInput(
                jobID: job.id,
                jobDisplayName: job.displayName,
                targetTimeMinutes: job.targetTimeMinutes,
                deadlineMinutes: job.deadlineMinutes,
                economy: job.economy,
                route: builder.route,
                enteredCardTypes: cardTypes
            )
        }
        return input
    }
}
