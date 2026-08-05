//
//  ExecutionPresentationTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct ExecutionPresentationTests {

    @Test func readyStateKeepsPlayerAtDepotWithLockedControls() throws {
        let input = try makeExecutionInput()
        let presentation = ExecutionPresentationState.ready(
            input: input,
            eventCount: input.enteredCoordinates.count
        )

        #expect(presentation.playerCoordinate == .depot)
        #expect(presentation.activeCoordinate == nil)
        #expect(presentation.elapsedMinutes == 0)
        #expect(presentation.damageEventCount == 0)
        #expect(presentation.phase == .ready)
        #expect(presentation.arePlanningControlsLocked)
        #expect(presentation.progressLabel == "0 / \(input.enteredCoordinates.count)")
    }

    @Test func snapshotsMatchEventHistoryProgression() throws {
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
        let prepared = ExecutionRunPreparer.prepare(input: input, seed: 42)
        let events = prepared.eventLog.events
        #expect(events.count == input.enteredCoordinates.count)

        for revealed in 1 ... events.count {
            let presentation = ExecutionPresentationState.snapshot(
                input: input,
                eventLog: prepared.eventLog,
                revealedEventCount: revealed
            )
            let event = events[revealed - 1]
            #expect(presentation.playerCoordinate == event.coordinate)
            #expect(presentation.elapsedMinutes == event.elapsedMinutesAfter)
            #expect(presentation.damageEventCount == event.cumulativeDamageEventCount)
            #expect(presentation.revealedEventCount == revealed)

            if revealed < events.count {
                #expect(presentation.phase == .running)
                #expect(presentation.activeCoordinate == event.coordinate)
            } else {
                #expect(presentation.phase == .completed)
                #expect(presentation.activeCoordinate == nil)
            }
        }

        #expect(prepared.state.elapsedMinutes == prepared.eventLog.totalElapsedMinutes)
        #expect(prepared.state.damageEventCount == prepared.eventLog.totalDamageEventCount)
    }

    @Test func consequenceDistinguishesMovementDelayAndDamage() throws {
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
        // Delay hit + damage hit.
        let damaged = ExecutionRunPreparer.prepare(input: input, scriptedRolls: [50, 1])
        let damageFrame = ExecutionPresentationState.snapshot(
            input: input,
            eventLog: damaged.eventLog,
            revealedEventCount: 1
        )
        #expect(damageFrame.lastConsequence == .damage)
        #expect(damageFrame.damageEventCount == 1)
        #expect(damageFrame.elapsedMinutes == 3)

        // Delay hit, damage miss.
        let delayed = ExecutionRunPreparer.prepare(input: input, scriptedRolls: [50, 16])
        let delayFrame = ExecutionPresentationState.snapshot(
            input: input,
            eventLog: delayed.eventLog,
            revealedEventCount: 1
        )
        #expect(delayFrame.lastConsequence == .delay)
        #expect(delayFrame.damageEventCount == 0)

        // Clear road movement.
        let clearInput = try makeExecutionInput()
        let clear = ExecutionRunPreparer.prepare(input: clearInput, seed: 1)
        let moveFrame = ExecutionPresentationState.snapshot(
            input: clearInput,
            eventLog: clear.eventLog,
            revealedEventCount: 1
        )
        #expect(moveFrame.lastConsequence == .movement)
    }

    @Test func presentationNeverMutatesSealedEventLog() throws {
        let input = try makeExecutionInput()
        let prepared = ExecutionRunPreparer.prepare(input: input, seed: 99)
        let originalEvents = prepared.eventLog.events

        _ = ExecutionPresentationState.snapshot(
            input: input,
            eventLog: prepared.eventLog,
            revealedEventCount: 3
        )
        _ = ExecutionPresentationState.snapshot(
            input: input,
            eventLog: prepared.eventLog,
            revealedEventCount: originalEvents.count
        )

        #expect(prepared.eventLog.events == originalEvents)
        #expect(prepared.eventLog.isSealed)
        #expect(prepared.eventLog.settlementSnapshot.events == originalEvents)
    }

    @Test func identicalSeedsProduceIdenticalPresentationFrames() throws {
        let input = try makeExecutionInput(cardTypes: [
            .heavyTraffic,
            .lightTraffic,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
        ])
        let first = ExecutionRunPreparer.prepare(input: input, seed: 123)
        let second = ExecutionRunPreparer.prepare(input: input, seed: 123)

        let firstFrames = (0 ... first.eventLog.events.count).map {
            ExecutionPresentationState.snapshot(
                input: input,
                eventLog: first.eventLog,
                revealedEventCount: $0
            )
        }
        let secondFrames = (0 ... second.eventLog.events.count).map {
            ExecutionPresentationState.snapshot(
                input: input,
                eventLog: second.eventLog,
                revealedEventCount: $0
            )
        }
        #expect(firstFrames == secondFrames)
    }

    @Test func planningControlLockDisablesEditingAfterConfirmation() {
        let lock = PlanningControlLock.afterConfirmation()
        #expect(lock.isEditingLocked)
        #expect(lock.canSelectCards == false)
        #expect(lock.canUndo == false)
        #expect(lock.canConfirm == false)
    }

    @Test func accessibilityIdentifiersCoverExecutionProgressSurface() {
        #expect(GridAccessibilityID.executionProgressPanel == "execution-progress-panel")
        #expect(GridAccessibilityID.executionProgress == "execution-progress")
        #expect(GridAccessibilityID.executionElapsed == "execution-elapsed")
        #expect(GridAccessibilityID.executionDamage == "execution-damage")
        #expect(GridAccessibilityID.executionStatus == "execution-status")
        #expect(GridAccessibilityID.executionConsequence == "execution-consequence")
        #expect(GridAccessibilityID.executionHandoff == "execution-handoff")
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
