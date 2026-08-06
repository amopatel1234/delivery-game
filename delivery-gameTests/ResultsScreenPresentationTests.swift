//
//  ResultsScreenPresentationTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct ResultsScreenPresentationTests {

    @Test func completedEarlyRunUsesCompletedHeadingAndReward() {
        let settlement = settle(elapsed: 8, target: 10, deadline: 16)
        let presentation = makePresentation(elapsed: 8, target: 10, deadline: 16)

        #expect(presentation.heading == "Delivery complete")
        #expect(presentation.headingTone == .completed)
        #expect(presentation.rewardAmount == settlement.finalReward)
        #expect(presentation.rewardAmount == 110)
        #expect(presentation.rewardCaption == "Reward earned")
    }

    @Test func failedRunUsesFailedHeadingAndZeroReward() {
        let settlement = settle(elapsed: 16, target: 10, deadline: 16, damage: 2)
        let presentation = makePresentation(elapsed: 16, target: 10, deadline: 16, damage: 2)

        #expect(presentation.heading == "Delivery failed")
        #expect(presentation.headingTone == .failed)
        #expect(presentation.rewardAmount == 0)
        #expect(presentation.rewardAmount == settlement.finalReward)
        #expect(presentation.rewardCaption == "No reward earned")
    }

    @Test func timingRowsExposeActualTargetDeadlineAndDamage() {
        let presentation = makePresentation(elapsed: 12, target: 10, deadline: 16, damage: 1)

        #expect(presentation.timingRows.map(\.id) == ["actual", "target", "deadline", "damage"])
        #expect(presentation.timingRows[0].value == "12 min")
        #expect(presentation.timingRows[1].value == "10 min")
        #expect(presentation.timingRows[2].value == "16 min")
        #expect(presentation.timingRows[3].value == "1")
    }

    @Test func breakdownRowsMatchSettlementComponents() {
        let settlement = settle(elapsed: 12, target: 10, deadline: 16, damage: 1)
        let presentation = makePresentation(elapsed: 12, target: 10, deadline: 16, damage: 1)

        #expect(presentation.breakdownRows.count == 5)
        #expect(presentation.breakdownRows.map(\.id) == [
            "baseReward",
            "earlyBonus",
            "latenessPenalty",
            "damagePenalty",
            "finalReward",
        ])
        #expect(presentation.breakdownRows[0].value == "+100")
        #expect(presentation.breakdownRows[1].value == "0")
        #expect(presentation.breakdownRows[2].value == "-40")
        #expect(presentation.breakdownRows[2].title == "Late penalty (2 min)")
        #expect(presentation.breakdownRows[3].value == "-20")
        #expect(presentation.breakdownRows[3].title == "Damage penalty (1)")
        #expect(presentation.breakdownRows[4].value == "\(settlement.finalReward)")
        #expect(presentation.breakdownRows[4].isEmphasized)
    }

    @Test func inputFromExecutionResultMatchesSettlement() throws {
        let input = try makeExecutionInput(
            targetTimeMinutes: 10,
            deadlineMinutes: 16,
            cardTypes: Array(repeating: .clearRoad, count: 8)
        )
        let prepared = ExecutionRunPreparer.prepare(input: input, seed: 1)
        let screenInput = ResultsScreenInput.from(result: prepared.result)
        let settlement = RewardSettler.settle(prepared.result)
        let presentation = ResultsScreenPresentation.make(from: screenInput)

        #expect(screenInput.breakdown.finalReward == settlement.finalReward)
        #expect(presentation.rewardAmount == settlement.finalReward)
        #expect(screenInput.recap == prepared.result.recap)
    }

    @Test func accessibilityIdentifiersAreStable() {
        #expect(GridAccessibilityID.resultsScreen == "results-screen")
        #expect(GridAccessibilityID.resultsHeading == "results-heading")
        #expect(GridAccessibilityID.resultsReward == "results-reward")
        #expect(GridAccessibilityID.resultsTiming == "results-timing")
        #expect(GridAccessibilityID.resultsBreakdown == "results-breakdown")
        #expect(GridAccessibilityID.resultsContinueButton == "results-continue-button")
        #expect(GridAccessibilityID.resultsTimingRow("actual") == "results-timing-actual")
        #expect(GridAccessibilityID.resultsBreakdownRow("finalReward") == "results-breakdown-finalReward")
    }

    private func makePresentation(
        elapsed: Int,
        target: Int,
        deadline: Int,
        damage: Int = 0
    ) -> ResultsScreenPresentation {
        let settlement = settle(elapsed: elapsed, target: target, deadline: deadline, damage: damage)
        let input = ResultsScreenInput(
            jobDisplayName: "Job 1",
            breakdown: OutcomeBreakdownBuilder.build(from: settlement),
            recap: ExecutionRecap(
                jobID: SeededJobCatalogue.defaultJobID,
                jobDisplayName: "Job 1",
                targetTimeMinutes: target,
                deadlineMinutes: deadline,
                entries: [],
                totalBaseTravelMinutes: elapsed,
                totalDelayMinutes: 0,
                totalElapsedMinutes: elapsed,
                totalDamageEvents: damage,
                delayedCardCount: 0
            )
        )
        return ResultsScreenPresentation.make(from: input)
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
