//
//  OutcomeEvaluatorTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct OutcomeEvaluatorTests {

    private let target = 10
    private let deadline = 16

    @Test func beforeTargetTimeIsCompletedEarly() {
        let evaluation = OutcomeEvaluator.evaluate(
            elapsedMinutes: target - 1,
            targetTimeMinutes: target,
            deadlineMinutes: deadline
        )

        #expect(evaluation.status == .completed)
        #expect(evaluation.timingBand == .early)
        #expect(evaluation.isCompleted)
    }

    @Test func exactlyAtTargetTimeIsCompletedOnTarget() {
        let evaluation = OutcomeEvaluator.evaluate(
            elapsedMinutes: target,
            targetTimeMinutes: target,
            deadlineMinutes: deadline
        )

        #expect(evaluation.status == .completed)
        #expect(evaluation.timingBand == .onTarget)
    }

    @Test func afterTargetBeforeDeadlineIsCompletedLate() {
        let justAfterTarget = OutcomeEvaluator.evaluate(
            elapsedMinutes: target + 1,
            targetTimeMinutes: target,
            deadlineMinutes: deadline
        )
        #expect(justAfterTarget.status == .completed)
        #expect(justAfterTarget.timingBand == .late)

        let justBeforeDeadline = OutcomeEvaluator.evaluate(
            elapsedMinutes: deadline - 1,
            targetTimeMinutes: target,
            deadlineMinutes: deadline
        )
        #expect(justBeforeDeadline.status == .completed)
        #expect(justBeforeDeadline.timingBand == .late)
    }

    @Test func atDeadlineFails() {
        let evaluation = OutcomeEvaluator.evaluate(
            elapsedMinutes: deadline,
            targetTimeMinutes: target,
            deadlineMinutes: deadline
        )

        #expect(evaluation.status == .failed)
        #expect(evaluation.timingBand == .missedDeadline)
        #expect(evaluation.isFailed)
    }

    @Test func afterDeadlineFails() {
        let evaluation = OutcomeEvaluator.evaluate(
            elapsedMinutes: deadline + 1,
            targetTimeMinutes: target,
            deadlineMinutes: deadline
        )

        #expect(evaluation.status == .failed)
        #expect(evaluation.timingBand == .missedDeadline)
    }

    @Test func missingDestinationFailsEvenWhenEarly() {
        let evaluation = OutcomeEvaluator.evaluate(
            elapsedMinutes: target - 2,
            targetTimeMinutes: target,
            deadlineMinutes: deadline,
            didReachDestination: false
        )

        #expect(evaluation.status == .failed)
        #expect(evaluation.timingBand == .early)
        #expect(evaluation.didReachDestination == false)
    }

    @Test func evaluationFromExecutionResultIsDeterministic() throws {
        let input = try makeExecutionInput(
            targetTimeMinutes: 10,
            deadlineMinutes: 16,
            cardTypes: Array(repeating: .clearRoad, count: 8)
        )
        // 8 clear roads → 8 minutes elapsed (before target 10).
        let firstResult = ExecutionRunPreparer.prepare(input: input, seed: 1).result
        let secondResult = ExecutionRunPreparer.prepare(input: input, seed: 1).result

        let first = OutcomeEvaluator.evaluate(firstResult)
        let second = OutcomeEvaluator.evaluate(secondResult)

        #expect(first == second)
        #expect(first.status == .completed)
        #expect(first.timingBand == .early)
        #expect(first.elapsedMinutes == 8)
        #expect(first.didReachDestination)
        #expect(first.damageEventCount == firstResult.damageEventCount)
    }

    @Test func lateCompletedRunFromExecutionResult() throws {
        let input = try makeExecutionInput(
            targetTimeMinutes: 6,
            deadlineMinutes: 20,
            cardTypes: [
                .clearRoad,
                .lightTraffic,
                .roadworks,
                .clearRoad,
                .clearRoad,
                .clearRoad,
                .clearRoad,
                .clearRoad,
            ]
        )
        // base 7 + delay 3 = 10 elapsed → after target 6, before deadline 20.
        let result = ExecutionRunPreparer.prepare(input: input, seed: 2).result
        let evaluation = OutcomeEvaluator.evaluate(result)

        #expect(result.elapsedMinutes == 10)
        #expect(evaluation.status == .completed)
        #expect(evaluation.timingBand == .late)
    }

    @Test func deadlineFailureFromExecutionResult() throws {
        let input = try makeExecutionInput(
            targetTimeMinutes: 5,
            deadlineMinutes: 8,
            cardTypes: [
                .clearRoad,
                .lightTraffic,
                .roadworks,
                .clearRoad,
                .clearRoad,
                .clearRoad,
                .clearRoad,
                .clearRoad,
            ]
        )
        // 10 elapsed ≥ deadline 8.
        let result = ExecutionRunPreparer.prepare(input: input, seed: 3).result
        let evaluation = OutcomeEvaluator.evaluate(result)

        #expect(result.elapsedMinutes == 10)
        #expect(evaluation.status == .failed)
        #expect(evaluation.timingBand == .missedDeadline)
    }

    @Test func allTimingBoundariesAroundTargetAndDeadline() {
        // Exhaustive minute scan across the authored window.
        for elapsed in 0 ... (deadline + 2) {
            let evaluation = OutcomeEvaluator.evaluate(
                elapsedMinutes: elapsed,
                targetTimeMinutes: target,
                deadlineMinutes: deadline
            )
            if elapsed >= deadline {
                #expect(evaluation.status == .failed)
                #expect(evaluation.timingBand == .missedDeadline)
            } else if elapsed < target {
                #expect(evaluation.status == .completed)
                #expect(evaluation.timingBand == .early)
            } else if elapsed == target {
                #expect(evaluation.status == .completed)
                #expect(evaluation.timingBand == .onTarget)
            } else {
                #expect(evaluation.status == .completed)
                #expect(evaluation.timingBand == .late)
            }
        }
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
