//
//  MaximumRewardEstimatorTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct MaximumRewardEstimatorTests {

    @Test func usesSharedEconomyConfiguration() {
        let custom = EconomyConfiguration(
            baseReward: 200,
            earlyBonusPerMinute: 10,
            latenessPenaltyPerMinute: 15,
            damagePenaltyPerEvent: 25,
            minimumReward: 0
        )
        let input = MaximumRewardEstimationInput(
            deterministicArrivalMinutes: 8,
            targetTimeMinutes: 10,
            deadlineMinutes: 16,
            economy: custom
        )

        #expect(MaximumRewardEstimator.estimate(input) == 220)
    }

    @Test func earlyArrivalAppliesEarlyBonus() {
        let input = makeInput(arrival: 8, target: 10, deadline: 16)

        // 100 + (10 - 8) * 5 = 110
        #expect(MaximumRewardEstimator.estimate(input) == 110)
    }

    @Test func onTargetArrivalReceivesBaseRewardOnly() {
        let input = makeInput(arrival: 10, target: 10, deadline: 16)

        #expect(MaximumRewardEstimator.estimate(input) == 100)
    }

    @Test func lateArrivalBeforeDeadlineAppliesLatenessPenalty() {
        let input = makeInput(arrival: 12, target: 10, deadline: 16)

        // 100 - (12 - 10) * 20 = 60
        #expect(MaximumRewardEstimator.estimate(input) == 60)
    }

    @Test func arrivalOneMinuteBeforeDeadlineStillCompletes() {
        let input = makeInput(arrival: 15, target: 10, deadline: 16)

        // 100 - 5 * 20 = 0
        #expect(MaximumRewardEstimator.estimate(input) == 0)
    }

    @Test func arrivalAtDeadlineFailsWithZeroReward() {
        let input = makeInput(arrival: 16, target: 10, deadline: 16)

        #expect(MaximumRewardEstimator.estimate(input) == 0)
    }

    @Test func arrivalAfterDeadlineFailsWithZeroReward() {
        let input = makeInput(arrival: 20, target: 10, deadline: 16)

        #expect(MaximumRewardEstimator.estimate(input) == 0)
    }

    @Test func excludesUnresolvedDamagePenalties() {
        let input = makeInput(arrival: 10, target: 10, deadline: 16)

        // Even though damagePenaltyPerEvent is 20, planning max excludes damage.
        #expect(MaximumRewardEstimator.estimate(input) == EconomyConfiguration.mvp.baseReward)
        #expect(input.economy.damagePenaltyPerEvent == 20)
    }

    @Test func clampsCompletedRewardToEconomyMinimum() {
        let economy = EconomyConfiguration(
            baseReward: 100,
            earlyBonusPerMinute: 5,
            latenessPenaltyPerMinute: 40,
            damagePenaltyPerEvent: 20,
            minimumReward: 0
        )
        let input = MaximumRewardEstimationInput(
            deterministicArrivalMinutes: 14,
            targetTimeMinutes: 10,
            deadlineMinutes: 16,
            economy: economy
        )

        // 100 - 4 * 40 = -60 → clamped to 0
        #expect(MaximumRewardEstimator.estimate(input) == 0)
    }

    @Test func neverExceedsTheoreticalMaximumForEquivalentInputs() {
        let targets = [9, 10, 12]
        let arrivals = [0, 5, 9, 10, 11, 15, 16, 20]

        for target in targets {
            for arrival in arrivals {
                let input = makeInput(arrival: arrival, target: target, deadline: target + 6)
                let estimate = MaximumRewardEstimator.estimate(input)
                let ceiling = MaximumRewardEstimator.theoreticalMaximum(for: input)

                #expect(estimate <= ceiling)
            }
        }
    }

    @Test func estimatesFromPlanningAnalysisResult() throws {
        var cells = GridCoordinate.allInRowMajorOrder.map {
            GridCell(coordinate: $0, cardType: .clearRoad)
        }
        cells[1] = GridCell(
            coordinate: GridCoordinate(row: 0, column: 1),
            cardType: .lightTraffic
        )
        let grid = try DeliveryGrid(cells: cells)
        let request = PlanningAnalysisRequest(
            route: Route(coordinates: [.depot, GridCoordinate(row: 0, column: 1)]),
            grid: grid,
            targetTimeMinutes: 10,
            deadlineMinutes: 16,
            economy: .mvp
        )
        let analysis = PlanningAnalyzer.analyze(request)

        // Light Traffic deterministic arrival = 2 → early by 8 → 100 + 40 = 140
        #expect(analysis.estimatedArrivalMinutes == 2)
        #expect(MaximumRewardEstimator.estimate(analysis: analysis) == 140)
    }

    @Test func theoreticalMaximumUsesTargetTimeEarlyBonusCeiling() {
        let input = makeInput(arrival: 0, target: 10, deadline: 16)

        #expect(MaximumRewardEstimator.theoreticalMaximum(for: input) == 150)
        #expect(MaximumRewardEstimator.estimate(input) == 150)
    }

    private func makeInput(
        arrival: Int,
        target: Int,
        deadline: Int,
        economy: EconomyConfiguration = .mvp
    ) -> MaximumRewardEstimationInput {
        MaximumRewardEstimationInput(
            deterministicArrivalMinutes: arrival,
            targetTimeMinutes: target,
            deadlineMinutes: deadline,
            economy: economy
        )
    }
}
