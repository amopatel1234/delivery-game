//
//  ExecutionRecapTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct ExecutionRecapTests {

    @Test func includesEveryResolvedCardOnceInOrder() throws {
        let input = try makeExecutionInput(cardTypes: [
            .clearRoad,
            .lightTraffic,
            .roadworks,
            .fastLane,
            .heavyTraffic,
            .clearRoad,
            .clearRoad,
            .clearRoad,
        ])
        let prepared = ExecutionRunPreparer.prepare(input: input, scriptedRolls: [51])
        let recap = ExecutionRecap.from(input: input, eventLog: prepared.eventLog)

        #expect(recap.entries.count == input.enteredCardTypes.count)
        #expect(recap.entries.map(\.enteredIndex) == Array(0..<input.enteredCardTypes.count))
        #expect(recap.entries.map(\.cardType) == input.enteredCardTypes)
        #expect(recap.entries.map(\.coordinate) == input.enteredCoordinates)
        #expect(Set(recap.entries.map(\.enteredIndex)).count == recap.entries.count)
    }

    @Test func recapMatchesEventHistoryFields() throws {
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
        let prepared = ExecutionRunPreparer.prepare(input: input, scriptedRolls: [50, 1])
        let events = prepared.eventLog.events
        let recap = ExecutionRecap.from(input: input, eventLog: prepared.eventLog)

        for (entry, event) in zip(recap.entries, events) {
            #expect(entry.enteredIndex == event.enteredIndex)
            #expect(entry.coordinate == event.coordinate)
            #expect(entry.cardType == event.cardType)
            #expect(entry.baseTravelMinutes == event.baseTravelMinutes)
            #expect(entry.delayMinutesApplied == event.delayMinutesApplied)
            #expect(entry.didDelay == event.didDelay)
            #expect(entry.didDamage == event.didDamage)
            #expect(entry.delayRoll == event.delayRoll)
            #expect(entry.damageRoll == event.damageRoll)
        }
    }

    @Test func totalsMatchExecutionStateAndSeparateMovementFromDelay() throws {
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
        let prepared = ExecutionRunPreparer.prepare(input: input, seed: 7)
        let recap = ExecutionRecap.from(input: input, state: prepared.state)

        #expect(recap.totalElapsedMinutes == prepared.state.elapsedMinutes)
        #expect(recap.totalDamageEvents == prepared.state.damageEventCount)
        #expect(recap.totalElapsedMinutes == recap.totalBaseTravelMinutes + recap.totalDelayMinutes)
        #expect(recap.totalBaseTravelMinutes == 6) // clear+light+roadworks+fast0+4clear = 1+1+1+0+4
        #expect(recap.totalDelayMinutes == 3) // light 1 + roadworks 2
        #expect(recap.delayedCardCount == 2)
        #expect(recap.totalDamageEvents == 0)
        #expect(recap.totalElapsedMinutes == 9)
    }

    @Test func damageAndDelaySummariesTrackHeavyTrafficOutcomes() throws {
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
        // Miss, then delay+damage.
        let prepared = ExecutionRunPreparer.prepare(input: input, scriptedRolls: [51, 50, 1])
        let recap = ExecutionRecap.from(input: input, eventLog: prepared.eventLog)

        #expect(recap.entries[0].didDelay == false)
        #expect(recap.entries[0].didDamage == false)
        #expect(recap.entries[0].delayMinutes == 0)
        #expect(recap.entries[1].didDelay == true)
        #expect(recap.entries[1].didDamage == true)
        #expect(recap.entries[1].delayMinutes == 2)
        #expect(recap.delayedCardCount == 1)
        #expect(recap.totalDamageEvents == 1)
        #expect(recap.totalDelayMinutes == 2)
        #expect(recap.totalElapsedMinutes == prepared.state.elapsedMinutes)
    }

    @Test func recapIsPresentationIndependentAndDeterministic() throws {
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
        let first = ExecutionRecap.from(
            input: input,
            eventLog: ExecutionRunPreparer.prepare(input: input, seed: 404).eventLog
        )
        let second = ExecutionRecap.from(
            input: input,
            eventLog: ExecutionRunPreparer.prepare(input: input, seed: 404).eventLog
        )
        #expect(first == second)
        #expect(first.jobID == input.jobID)
        #expect(first.jobDisplayName == input.jobDisplayName)
        #expect(first.targetTimeMinutes == input.targetTimeMinutes)
        #expect(first.deadlineMinutes == input.deadlineMinutes)
    }

    @Test func accessibilityIdentifiersCoverRecapSurface() {
        #expect(GridAccessibilityID.executionRecap == "execution-recap")
        #expect(GridAccessibilityID.executionRecapSummary == "execution-recap-summary")
        #expect(GridAccessibilityID.executionRecapList == "execution-recap-list")
        #expect(GridAccessibilityID.executionRecapEntry(0) == "execution-recap-entry-0")
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
