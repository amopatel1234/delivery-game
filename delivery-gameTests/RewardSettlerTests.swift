//
//  RewardSettlerTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct RewardSettlerTests {

    @Test func usesSharedEconomyConfiguration() {
        let economy = EconomyConfiguration(
            baseReward: 200,
            earlyBonusPerMinute: 10,
            latenessPenaltyPerMinute: 15,
            damagePenaltyPerEvent: 25,
            minimumReward: 0
        )
        let evaluation = OutcomeEvaluator.evaluate(
            elapsedMinutes: 8,
            targetTimeMinutes: 10,
            deadlineMinutes: 16,
            damageEventCount: 1
        )
        let settlement = RewardSettler.settle(evaluation: evaluation, economy: economy)

        // 200 + 2*10 - 25 = 195
        #expect(settlement.economy == economy)
        #expect(settlement.baseReward == 200)
        #expect(settlement.earlyMinutes == 2)
        #expect(settlement.earlyBonus == 20)
        #expect(settlement.damagePenalty == 25)
        #expect(settlement.finalReward == 195)
    }

    @Test func earlyArrivalAppliesEarlyBonus() {
        let settlement = settle(elapsed: 8, target: 10, deadline: 16)

        #expect(settlement.status == .completed)
        #expect(settlement.earlyMinutes == 2)
        #expect(settlement.earlyBonus == 10)
        #expect(settlement.lateMinutes == 0)
        #expect(settlement.latenessPenalty == 0)
        #expect(settlement.finalReward == 110)
    }

    @Test func onTargetReceivesBaseRewardOnly() {
        let settlement = settle(elapsed: 10, target: 10, deadline: 16)

        #expect(settlement.earlyBonus == 0)
        #expect(settlement.latenessPenalty == 0)
        #expect(settlement.finalReward == 100)
    }

    @Test func lateArrivalAppliesLatenessPenalty() {
        let settlement = settle(elapsed: 12, target: 10, deadline: 16)

        #expect(settlement.lateMinutes == 2)
        #expect(settlement.latenessPenalty == 40)
        #expect(settlement.finalReward == 60)
    }

    @Test func damagePenaltyAppliesOnCompletedRuns() {
        let settlement = settle(elapsed: 10, target: 10, deadline: 16, damage: 2)

        #expect(settlement.damageEventCount == 2)
        #expect(settlement.damagePenalty == 40)
        #expect(settlement.finalReward == 60)
    }

    @Test func lateAndDamagedRunCombinesPenalties() {
        let settlement = settle(elapsed: 12, target: 10, deadline: 16, damage: 1)

        // 100 - 40 - 20 = 40
        #expect(settlement.finalReward == 40)
    }

    @Test func clampsCompletedRewardToZero() {
        let economy = EconomyConfiguration(
            baseReward: 100,
            earlyBonusPerMinute: 5,
            latenessPenaltyPerMinute: 40,
            damagePenaltyPerEvent: 20,
            minimumReward: 0
        )
        let evaluation = OutcomeEvaluator.evaluate(
            elapsedMinutes: 14,
            targetTimeMinutes: 10,
            deadlineMinutes: 16,
            damageEventCount: 0
        )
        let settlement = RewardSettler.settle(evaluation: evaluation, economy: economy)

        // 100 - 4*40 = -60 → clamp 0
        #expect(settlement.rawCompletedReward == -60)
        #expect(settlement.finalReward == 0)
        #expect(settlement.finalReward >= economy.minimumReward)
    }

    @Test func failedRunsAlwaysReturnZeroReward() {
        let atDeadline = settle(elapsed: 16, target: 10, deadline: 16, damage: 0)
        #expect(atDeadline.isFailed)
        #expect(atDeadline.finalReward == 0)

        let afterDeadline = settle(elapsed: 20, target: 10, deadline: 16, damage: 3)
        #expect(afterDeadline.isFailed)
        #expect(afterDeadline.damagePenalty == 60)
        #expect(afterDeadline.finalReward == 0)

        let missedDestination = RewardSettler.settle(
            evaluation: OutcomeEvaluator.evaluate(
                elapsedMinutes: 8,
                targetTimeMinutes: 10,
                deadlineMinutes: 16,
                damageEventCount: 0,
                didReachDestination: false
            ),
            economy: .mvp
        )
        #expect(missedDestination.isFailed)
        #expect(missedDestination.earlyBonus == 10)
        #expect(missedDestination.finalReward == 0)
    }

    @Test func finalRewardIsNeverNegative() {
        let cases: [(Int, Int, Int, Int)] = [
            (0, 10, 16, 0),
            (8, 10, 16, 0),
            (10, 10, 16, 5),
            (15, 10, 16, 2),
            (16, 10, 16, 4),
            (20, 10, 16, 1),
        ]
        for (elapsed, target, deadline, damage) in cases {
            let settlement = settle(
                elapsed: elapsed,
                target: target,
                deadline: deadline,
                damage: damage
            )
            #expect(settlement.finalReward >= 0)
        }
    }

    @Test func matchesMaximumRewardEstimatorWhenNoDamage() {
        let arrivals = [0, 8, 10, 12, 15, 16, 20]
        for arrival in arrivals {
            let estimationInput = MaximumRewardEstimationInput(
                deterministicArrivalMinutes: arrival,
                targetTimeMinutes: 10,
                deadlineMinutes: 16,
                economy: .mvp
            )
            let settlement = settle(elapsed: arrival, target: 10, deadline: 16, damage: 0)
            #expect(settlement.finalReward == MaximumRewardEstimator.estimate(estimationInput))
        }
    }

    @Test func settlesFromExecutionResultWithoutRandomness() throws {
        let input = try makeExecutionInput(
            targetTimeMinutes: 10,
            deadlineMinutes: 16,
            cardTypes: Array(repeating: .clearRoad, count: 8)
        )
        // 8 minutes → early by 2 → 110
        let first = RewardSettler.settle(ExecutionRunPreparer.prepare(input: input, seed: 1).result)
        let second = RewardSettler.settle(ExecutionRunPreparer.prepare(input: input, seed: 99).result)

        #expect(first.finalReward == 110)
        #expect(first.earlyMinutes == 2)
        #expect(first == second)
        #expect(first.evaluation.elapsedMinutes == 8)
    }

    @Test func damagedExecutionResultAppliesPenalty() throws {
        let input = try makeExecutionInput(
            targetTimeMinutes: 12,
            deadlineMinutes: 20,
            cardTypes: [
                .heavyTraffic,
                .clearRoad,
                .clearRoad,
                .clearRoad,
                .clearRoad,
                .clearRoad,
                .clearRoad,
                .clearRoad,
            ]
        )
        // delay+damage: 1+2 + 7 = 10 elapsed, 1 damage → early by 2 → 100+10-20 = 90
        let settlement = RewardSettler.settle(
            ExecutionRunPreparer.prepare(input: input, scriptedRolls: [50, 1]).result
        )

        #expect(settlement.evaluation.status == .completed)
        #expect(settlement.evaluation.elapsedMinutes == 10)
        #expect(settlement.damageEventCount == 1)
        #expect(settlement.earlyBonus == 10)
        #expect(settlement.damagePenalty == 20)
        #expect(settlement.finalReward == 90)
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

