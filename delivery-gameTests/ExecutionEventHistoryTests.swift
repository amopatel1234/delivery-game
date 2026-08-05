//
//  ExecutionEventHistoryTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct ExecutionEventHistoryTests {

    @Test func recordsOneEventPerResolvedCardInOrder() throws {
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
        var engine = ExecutionEngine(input: input)
        _ = engine.start()
        guard case .completed(let state) = engine.runToCompletion() else {
            Issue.record("Expected completion")
            return
        }

        #expect(state.eventLog.events.count == input.enteredCardTypes.count)
        #expect(state.eventLog.events.map(\.enteredIndex) == Array(0..<input.enteredCardTypes.count))
        #expect(state.eventLog.events.map(\.cardType) == input.enteredCardTypes)
        #expect(state.eventLog.events.map(\.coordinate) == input.enteredCoordinates)
    }

    @Test func eventTotalsMatchLiveExecutionState() throws {
        let input = try makeExecutionInput(cardTypes: [
            .clearRoad,
            .lightTraffic,
            .fastLane,
            .roadworks,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
        ])
        var engine = ExecutionEngine(input: input)
        _ = engine.start()
        guard case .completed(let state) = engine.runToCompletion() else {
            Issue.record("Expected completion")
            return
        }

        #expect(state.eventLog.totalElapsedMinutes == state.elapsedMinutes)
        #expect(state.eventLog.totalDamageEventCount == state.damageEventCount)
        #expect(state.elapsedMinutes == 10)
        #expect(state.damageEventCount == 0)

        // Running totals on each event stay consistent with prefix sums.
        var elapsed = 0
        var damage = 0
        for event in state.eventLog.events {
            elapsed += event.minutesAdded
            if event.didDamage { damage += 1 }
            #expect(event.elapsedMinutesAfter == elapsed)
            #expect(event.cumulativeDamageEventCount == damage)
        }
    }

    @Test func recordsOnlyConsumedRollsForHeavyTraffic() throws {
        let input = try makeHeavyTrafficInput(cardTypes: [
            .heavyTraffic,
            .heavyTraffic,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
        ])
        // Card 0: delay miss (51) — only delay roll.
        // Card 1: delay hit (50), damage hit (1) — both rolls.
        var engine = ExecutionEngine(input: input, scriptedRolls: [51, 50, 1])
        _ = engine.start()
        guard case .completed(let state) = engine.runToCompletion() else {
            Issue.record("Expected completion")
            return
        }

        let first = state.eventLog.events[0]
        #expect(first.cardType == .heavyTraffic)
        #expect(first.didDelay == false)
        #expect(first.didDamage == false)
        #expect(first.delayRoll == 51)
        #expect(first.damageRoll == nil)
        #expect(first.consumedRolls == [51])

        let second = state.eventLog.events[1]
        #expect(second.cardType == .heavyTraffic)
        #expect(second.didDelay == true)
        #expect(second.didDamage == true)
        #expect(second.delayRoll == 50)
        #expect(second.damageRoll == 1)
        #expect(second.consumedRolls == [50, 1])
        #expect(second.cumulativeDamageEventCount == 1)

        // Non-hazard cards never record rolls.
        for event in state.eventLog.events.dropFirst(2) {
            #expect(event.delayRoll == nil)
            #expect(event.damageRoll == nil)
            #expect(event.consumedRolls.isEmpty)
        }
    }

    @Test func fixedHazardModeRecordsNoRolls() throws {
        let input = try makeHeavyTrafficInput()
        var engine = ExecutionEngine(input: input, heavyTrafficHazard: .delayedAndDamaged)
        _ = engine.start()
        guard case .completed(let state) = engine.runToCompletion() else {
            Issue.record("Expected completion")
            return
        }

        let heavy = state.eventLog.events[0]
        #expect(heavy.didDelay == true)
        #expect(heavy.didDamage == true)
        #expect(heavy.delayRoll == nil)
        #expect(heavy.damageRoll == nil)
        #expect(heavy.consumedRolls.isEmpty)
    }

    @Test func eventHistoryIsSealedAfterCompletion() throws {
        let input = try makeExecutionInput()
        var engine = ExecutionEngine(input: input)
        _ = engine.start()
        guard case .completed(let state) = engine.runToCompletion() else {
            Issue.record("Expected completion")
            return
        }

        #expect(state.eventLog.isSealed)

        var sealedLog = state.eventLog
        let extra = ExecutionResolutionEvent(
            enteredIndex: 99,
            coordinate: .destination,
            cardType: .clearRoad,
            baseTravelMinutes: 1,
            delayMinutesApplied: 0,
            didDelay: false,
            didDamage: false,
            delayRoll: nil,
            damageRoll: nil,
            elapsedMinutesAfter: state.elapsedMinutes + 1,
            cumulativeDamageEventCount: state.damageEventCount
        )
        #expect(sealedLog.record(extra) == .sealed)
        #expect(sealedLog.events.count == state.eventLog.events.count)
    }

    @Test func settlementSnapshotIsSelfContained() throws {
        let input = try makeHeavyTrafficInput(cardTypes: [
            .heavyTraffic,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
        ])
        var engine = ExecutionEngine(input: input, scriptedRolls: [50, 15])
        _ = engine.start()
        guard case .completed(let state) = engine.runToCompletion() else {
            Issue.record("Expected completion")
            return
        }

        let snapshot = state.eventLog.settlementSnapshot
        #expect(snapshot.events == state.eventLog.events)
        #expect(snapshot.totalElapsedMinutes == state.elapsedMinutes)
        #expect(snapshot.totalDamageEventCount == state.damageEventCount)
        #expect(snapshot.totalElapsedMinutes == 10) // 1+2 + 7
        #expect(snapshot.totalDamageEventCount == 1)

        // Settlement must not need ExecutionState — recompute from events alone.
        #expect(snapshot.events.last?.elapsedMinutesAfter == snapshot.totalElapsedMinutes)
        #expect(snapshot.events.filter(\.didDamage).count == snapshot.totalDamageEventCount)
    }

    @Test func identicalSeedsProduceIdenticalEventHistory() throws {
        let input = try makeHeavyTrafficInput()

        var first = ExecutionEngine(input: input, seed: 77)
        _ = first.start()
        guard case .completed(let firstState) = first.runToCompletion() else {
            Issue.record("Expected first completion")
            return
        }

        var second = ExecutionEngine(input: input, seed: 77)
        _ = second.start()
        guard case .completed(let secondState) = second.runToCompletion() else {
            Issue.record("Expected second completion")
            return
        }

        #expect(firstState.eventLog.events == secondState.eventLog.events)
        #expect(firstState.eventLog.settlementSnapshot == secondState.eventLog.settlementSnapshot)
    }

    private func makeHeavyTrafficInput(
        cardTypes overrideTypes: [CardType]? = nil
    ) throws -> ExecutionInput {
        try makeExecutionInput(cardTypes: overrideTypes ?? [
            .heavyTraffic,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
            .clearRoad,
        ])
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
