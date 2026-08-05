//
//  ExecutionResultTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct ExecutionResultTests {

    @Test func finishProducesImmutableResultWithEpic4Inputs() throws {
        let input = try makeExecutionInput(cardTypes: [
            .clearRoad,
            .lightTraffic,
            .roadworks,
            .fastLane,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
        ])
        var engine = ExecutionEngine(input: input, seed: 11)
        _ = engine.start()
        guard case .completed = engine.runToCompletion() else {
            Issue.record("Expected run to complete")
            return
        }

        guard case .completed(let result) = engine.finish() else {
            Issue.record("Expected finish to produce a result")
            return
        }

        #expect(result.input == input)
        #expect(result.economy == input.economy)
        #expect(result.jobID == input.jobID)
        #expect(result.targetTimeMinutes == input.targetTimeMinutes)
        #expect(result.deadlineMinutes == input.deadlineMinutes)
        #expect(result.elapsedMinutes == engine.state.elapsedMinutes)
        #expect(result.damageEventCount == engine.state.damageEventCount)
        #expect(result.eventLog.isSealed)
        #expect(result.eventLog.events.count == input.enteredCardTypes.count)
        #expect(result.settlementSnapshot.totalElapsedMinutes == result.elapsedMinutes)
        #expect(result.settlementSnapshot.totalDamageEventCount == result.damageEventCount)
        #expect(result.recap.totalElapsedMinutes == result.elapsedMinutes)
        #expect(result.recap.totalDamageEvents == result.damageEventCount)
        #expect(result.didReachDestination)
        #expect(result.elapsedMinutes == 10)
    }

    @Test func transitionOccursExactlyOnce() throws {
        let input = try makeExecutionInput()
        var engine = ExecutionEngine(input: input, seed: 3)
        _ = engine.start()
        _ = engine.runToCompletion()

        guard case .completed(let first) = engine.finish() else {
            Issue.record("Expected first finish to succeed")
            return
        }

        guard case .rejected(let reason) = engine.finish() else {
            Issue.record("Expected duplicate finish to be rejected")
            return
        }
        #expect(reason == .alreadyTransitioned)

        // Second call must not change the first immutable payload.
        #expect(first.eventLog.events.count == input.enteredCoordinates.count)
    }

    @Test func finishBeforeCompletionIsRejected() throws {
        let input = try makeExecutionInput()
        var engine = ExecutionEngine(input: input, seed: 5)

        guard case .rejected(let beforeStart) = engine.finish() else {
            Issue.record("Expected finish before start to be rejected")
            return
        }
        #expect(beforeStart == .notCompleted)

        _ = engine.start()
        guard case .rejected(let whileRunning) = engine.finish() else {
            Issue.record("Expected finish while running to be rejected")
            return
        }
        #expect(whileRunning == .notCompleted)
    }

    @Test func executionCannotContinueAfterCompletion() throws {
        let input = try makeExecutionInput()
        var engine = ExecutionEngine(input: input, seed: 9)
        _ = engine.start()
        _ = engine.runToCompletion()
        _ = engine.finish()

        guard case .rejected(let advanceReason) = engine.advance() else {
            Issue.record("Expected advance after completion to be rejected")
            return
        }
        #expect(advanceReason == .alreadyCompleted)

        guard case .rejected(let runReason) = engine.runToCompletion() else {
            Issue.record("Expected runToCompletion after completion to be rejected")
            return
        }
        #expect(runReason == .alreadyCompleted)
    }

    @Test func resultDoesNotDependOnPresentationAndIsDeterministic() throws {
        let input = try makeExecutionInput(cardTypes: [
            .heavyTraffic,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
        ])

        let first = ExecutionRunPreparer.prepare(input: input, seed: 77).result
        let second = ExecutionRunPreparer.prepare(input: input, seed: 77).result

        #expect(first == second)
        #expect(first.recap == second.recap)
        #expect(first.eventLog.events == second.eventLog.events)

        // Presentation frames built from the same history must not alter the result.
        _ = ExecutionPresentationState.snapshot(
            input: input,
            eventLog: first.eventLog,
            revealedEventCount: first.eventLog.events.count
        )
        #expect(
            first
                == ExecutionRunPreparer.prepare(input: input, seed: 77).result
        )
    }

    @Test func resultTracksDamageTotalsFromEventHistory() throws {
        let input = try makeExecutionInput(cardTypes: [
            .heavyTraffic,
            .heavyTraffic,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
        ])
        let result = ExecutionRunPreparer.prepare(
            input: input,
            scriptedRolls: [51, 50, 1]
        ).result

        #expect(result.damageEventCount == 1)
        #expect(result.recap.totalDamageEvents == 1)
        #expect(result.eventLog.events[0].didDamage == false)
        #expect(result.eventLog.events[1].didDamage == true)
        #expect(result.didReachDestination)
    }

    private func makeExecutionInput(
        cardTypes: [CardType]? = nil
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

        var cells = GridCoordinate.allInRowMajorOrder.map {
            GridCell(coordinate: $0, cardType: .clearRoad)
        }
        if let cardTypes {
            precondition(cardTypes.count == path.count)
            for (coordinate, cardType) in zip(path, cardTypes) {
                if let index = cells.firstIndex(where: { $0.coordinate == coordinate }) {
                    cells[index] = GridCell(coordinate: coordinate, cardType: cardType)
                }
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
                enteredCardTypes: cardTypes ?? []
            )
        }
        return input
    }
}
