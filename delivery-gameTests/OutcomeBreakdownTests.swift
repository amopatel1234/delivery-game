//
//  OutcomeBreakdownTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct OutcomeBreakdownTests {

    @Test func mapsSettlementFieldsExactly() {
        let settlement = settle(elapsed: 12, target: 10, deadline: 16, damage: 1)
        let breakdown = OutcomeBreakdownBuilder.build(from: settlement)

        #expect(breakdown.status == settlement.status)
        #expect(breakdown.timingBand == settlement.timingBand)
        #expect(breakdown.elapsedMinutes == settlement.evaluation.elapsedMinutes)
        #expect(breakdown.targetTimeMinutes == settlement.evaluation.targetTimeMinutes)
        #expect(breakdown.deadlineMinutes == settlement.evaluation.deadlineMinutes)
        #expect(breakdown.damageEventCount == settlement.damageEventCount)
        #expect(breakdown.didReachDestination == settlement.evaluation.didReachDestination)
        #expect(breakdown.baseReward == settlement.baseReward)
        #expect(breakdown.earlyMinutes == settlement.earlyMinutes)
        #expect(breakdown.earlyBonus == settlement.earlyBonus)
        #expect(breakdown.lateMinutes == settlement.lateMinutes)
        #expect(breakdown.latenessPenalty == settlement.latenessPenalty)
        #expect(breakdown.damagePenalty == settlement.damagePenalty)
        #expect(breakdown.rawCompletedReward == settlement.rawCompletedReward)
        #expect(breakdown.finalReward == settlement.finalReward)
    }

    @Test func earlyRunIncludesZeroLateAndDamageRows() {
        let breakdown = OutcomeBreakdownBuilder.build(from: settle(elapsed: 8, target: 10, deadline: 16))

        #expect(breakdown.earlyBonus == 10)
        #expect(breakdown.latenessPenalty == 0)
        #expect(breakdown.damagePenalty == 0)
        #expect(breakdown.finalReward == 110)

        let items = breakdown.rewardLineItems
        #expect(items.count == 5)
        #expect(items[1].kind == .earlyBonus)
        #expect(items[1].amount == 10)
        #expect(items[1].quantity == 2)
        #expect(items[2].kind == .latenessPenalty)
        #expect(items[2].amount == 0)
        #expect(items[3].kind == .damagePenalty)
        #expect(items[3].amount == 0)
    }

    @Test func onTargetRunKeepsZeroTimingAdjustments() {
        let breakdown = OutcomeBreakdownBuilder.build(from: settle(elapsed: 10, target: 10, deadline: 16))

        #expect(breakdown.earlyMinutes == 0)
        #expect(breakdown.earlyBonus == 0)
        #expect(breakdown.lateMinutes == 0)
        #expect(breakdown.latenessPenalty == 0)
        #expect(breakdown.finalReward == 100)
    }

    @Test func lateRunIncludesLatenessPenaltyRow() {
        let breakdown = OutcomeBreakdownBuilder.build(from: settle(elapsed: 12, target: 10, deadline: 16))

        #expect(breakdown.lateMinutes == 2)
        #expect(breakdown.latenessPenalty == 40)
        #expect(breakdown.finalReward == 60)

        let lateItem = breakdown.rewardLineItems.first { $0.kind == .latenessPenalty }
        #expect(lateItem?.amount == 40)
        #expect(lateItem?.isDeduction == true)
        #expect(lateItem?.quantity == 2)
    }

    @Test func damagedRunIncludesDamagePenaltyRow() {
        let breakdown = OutcomeBreakdownBuilder.build(from: settle(elapsed: 10, target: 10, deadline: 16, damage: 2))

        #expect(breakdown.damageEventCount == 2)
        #expect(breakdown.damagePenalty == 40)
        #expect(breakdown.finalReward == 60)

        let damageItem = breakdown.rewardLineItems.first { $0.kind == .damagePenalty }
        #expect(damageItem?.amount == 40)
        #expect(damageItem?.isDeduction == true)
        #expect(damageItem?.quantity == 2)
    }

    @Test func failedRunPreservesComponentsWithZeroFinalReward() {
        let breakdown = OutcomeBreakdownBuilder.build(from: settle(elapsed: 16, target: 10, deadline: 16, damage: 2))

        #expect(breakdown.isFailed)
        #expect(breakdown.latenessPenalty == 0)
        #expect(breakdown.damagePenalty == 40)
        #expect(breakdown.rawCompletedReward == 60)
        #expect(breakdown.finalReward == 0)

        let finalItem = breakdown.rewardLineItems.first { $0.kind == .finalReward }
        #expect(finalItem?.amount == 0)
    }

    @Test func clampedRunMatchesSettlementFinalReward() {
        let economy = EconomyConfiguration(
            baseReward: 100,
            earlyBonusPerMinute: 5,
            latenessPenaltyPerMinute: 40,
            damagePenaltyPerEvent: 20,
            minimumReward: 0
        )
        let settlement = RewardSettler.settle(
            evaluation: OutcomeEvaluator.evaluate(
                elapsedMinutes: 14,
                targetTimeMinutes: 10,
                deadlineMinutes: 16
            ),
            economy: economy
        )
        let breakdown = OutcomeBreakdownBuilder.build(from: settlement)

        #expect(breakdown.rawCompletedReward == -60)
        #expect(breakdown.finalReward == 0)
        #expect(breakdown.finalReward == settlement.finalReward)
    }

    @Test func buildsDeterministicallyFromExecutionResult() throws {
        let input = try makeExecutionInput(
            targetTimeMinutes: 10,
            deadlineMinutes: 16,
            cardTypes: Array(repeating: .clearRoad, count: 8)
        )
        let result = ExecutionRunPreparer.prepare(input: input, seed: 1).result
        let settlement = RewardSettler.settle(result)

        let first = OutcomeBreakdownBuilder.build(from: result)
        let second = OutcomeBreakdownBuilder.build(from: result)

        #expect(first == second)
        #expect(first.finalReward == settlement.finalReward)
        #expect(first.earlyBonus == settlement.earlyBonus)
        #expect(first.elapsedMinutes == settlement.evaluation.elapsedMinutes)
    }

    @Test func rewardLineItemsAlwaysIncludeEveryComponentKind() {
        let scenarios: [RewardSettlement] = [
            settle(elapsed: 8, target: 10, deadline: 16),
            settle(elapsed: 10, target: 10, deadline: 16),
            settle(elapsed: 12, target: 10, deadline: 16, damage: 1),
            settle(elapsed: 16, target: 10, deadline: 16),
        ]

        for settlement in scenarios {
            let breakdown = OutcomeBreakdownBuilder.build(from: settlement)
            let kinds = Set(breakdown.rewardLineItems.map(\.kind))
            #expect(kinds == Set(OutcomeBreakdownLineKind.allCases))
        }
    }

    private func settle(
        elapsed: Int,
        target: Int,
        deadline: Int,
        damage: Int = 0
    ) -> RewardSettlement {
        RewardSettler.settle(
            evaluation: OutcomeEvaluator.evaluate(
                elapsedMinutes: elapsed,
                targetTimeMinutes: target,
                deadlineMinutes: deadline,
                damageEventCount: damage
            ),
            economy: .mvp
        )
    }

    private func makeExecutionInput(
        targetTimeMinutes: Int,
        deadlineMinutes: Int,
        cardTypes: [CardType]
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
        precondition(cardTypes.count == path.count)

        var builder = RouteBuilder()
        for coordinate in path {
            let result = builder.select(coordinate)
            guard case .accepted = result else {
                Issue.record("Expected path step \(coordinate) to be accepted")
                break
            }
        }

        return ExecutionInput(
            jobID: job.id,
            jobDisplayName: job.displayName,
            targetTimeMinutes: targetTimeMinutes,
            deadlineMinutes: deadlineMinutes,
            economy: job.economy,
            route: builder.route,
            enteredCardTypes: cardTypes
        )
    }
}
