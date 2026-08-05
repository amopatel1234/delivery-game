//
//  ExecutionEngineTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct ExecutionEngineTests {

    @Test func startsIdleAndDoesNotMutateInput() throws {
        let input = try makeExecutionInput()
        var engine = ExecutionEngine(input: input)

        #expect(engine.state.phase == .idle)
        #expect(engine.state.nextEnteredIndex == 0)
        #expect(engine.state.resolvedSteps.isEmpty)
        #expect(engine.state.currentCoordinate == .depot)
        #expect(engine.input.route.coordinates == input.route.coordinates)
        #expect(engine.input.jobID == input.jobID)
    }

    @Test func startTransitionsToRunningOnce() throws {
        let input = try makeExecutionInput()
        var engine = ExecutionEngine(input: input)

        guard case .started(let started) = engine.start() else {
            Issue.record("Expected start to succeed")
            return
        }
        #expect(started.phase == .running)
        #expect(engine.state.phase == .running)

        guard case .rejected(let reason) = engine.start() else {
            Issue.record("Expected duplicate start to be rejected")
            return
        }
        #expect(reason == .alreadyStarted)
    }

    @Test func advanceBeforeStartIsRejected() throws {
        var engine = ExecutionEngine(input: try makeExecutionInput())

        guard case .rejected(let reason) = engine.advance() else {
            Issue.record("Expected advance before start to be rejected")
            return
        }
        #expect(reason == .notRunning)
    }

    @Test func resolvesEnteredCardsSequentiallySkippingDepot() throws {
        let input = try makeExecutionInput()
        var engine = ExecutionEngine(input: input)
        _ = engine.start()

        var resolvedCoordinates: [GridCoordinate] = []
        while engine.state.phase == .running {
            switch engine.advance() {
            case .advanced(let step, let state):
                resolvedCoordinates.append(step.coordinate)
                #expect(step.enteredIndex == resolvedCoordinates.count - 1)
                #expect(step.cardType == input.enteredCardTypes[step.enteredIndex])
                #expect(state.resolvedSteps.count == resolvedCoordinates.count)
            case .completed(let state):
                resolvedCoordinates = state.resolvedSteps.map(\.coordinate)
                #expect(state.phase == .completed)
            case .rejected:
                Issue.record("Unexpected rejection during sequential resolve")
                return
            }
        }

        #expect(resolvedCoordinates == input.enteredCoordinates)
        #expect(resolvedCoordinates.contains(.depot) == false)
        #expect(engine.state.resolvedSteps.count == input.enteredCoordinates.count)
        #expect(engine.state.phase == .completed)
        #expect(engine.state.currentCoordinate == .destination)
    }

    @Test func runToCompletionProducesDeterministicState() throws {
        let input = try makeExecutionInput()

        var first = ExecutionEngine(input: input)
        _ = first.start()
        guard case .completed(let firstState) = first.runToCompletion() else {
            Issue.record("Expected first run to complete")
            return
        }

        var second = ExecutionEngine(input: input)
        _ = second.start()
        guard case .completed(let secondState) = second.runToCompletion() else {
            Issue.record("Expected second run to complete")
            return
        }

        #expect(firstState.phase == .completed)
        #expect(secondState.phase == .completed)
        #expect(firstState.resolvedSteps.count == secondState.resolvedSteps.count)
        #expect(firstState.nextEnteredIndex == secondState.nextEnteredIndex)
        #expect(firstState.elapsedMinutes == secondState.elapsedMinutes)
        #expect(firstState.damageEventCount == secondState.damageEventCount)
        #expect(firstState.elapsedMinutes > 0)

        for (lhs, rhs) in zip(firstState.resolvedSteps, secondState.resolvedSteps) {
            #expect(lhs.enteredIndex == rhs.enteredIndex)
            #expect(lhs.coordinate == rhs.coordinate)
            #expect(lhs.cardType == rhs.cardType)
            #expect(lhs.minutesAdded == rhs.minutesAdded)
            #expect(lhs.didDelay == rhs.didDelay)
            #expect(lhs.didDamage == rhs.didDamage)
        }
    }

    @Test func accumulatesTravelTimeFromResolvedCards() throws {
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

        // clear 1 + light 2 + fast 0 + roadworks 3 + four clear 4 = 10
        #expect(state.elapsedMinutes == 10)
        #expect(state.damageEventCount == 0)
        #expect(state.resolvedSteps.map(\.cardType) == input.enteredCardTypes)
    }

    @Test func heavyTrafficDamageAccumulatesOnlyWhenHazardSaysSo() throws {
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

        var safeEngine = ExecutionEngine(input: input, heavyTrafficHazard: .noHazard)
        _ = safeEngine.start()
        guard case .completed(let safeState) = safeEngine.runToCompletion() else {
            Issue.record("Expected safe completion")
            return
        }
        #expect(safeState.elapsedMinutes == 8) // 1 + 7*1
        #expect(safeState.damageEventCount == 0)

        var riskyEngine = ExecutionEngine(
            input: input,
            heavyTrafficHazard: .delayedAndDamaged
        )
        _ = riskyEngine.start()
        guard case .completed(let riskyState) = riskyEngine.runToCompletion() else {
            Issue.record("Expected risky completion")
            return
        }
        #expect(riskyState.elapsedMinutes == 10) // 1+2 + 7
        #expect(riskyState.damageEventCount == 1)
    }

    @Test func preventsAdvanceAfterCompletion() throws {
        var engine = ExecutionEngine(input: try makeExecutionInput())
        _ = engine.start()
        _ = engine.runToCompletion()

        guard case .rejected(let reason) = engine.advance() else {
            Issue.record("Expected advance after completion to be rejected")
            return
        }
        #expect(reason == .alreadyCompleted)

        guard case .rejected(let again) = engine.runToCompletion() else {
            Issue.record("Expected runToCompletion after completion to be rejected")
            return
        }
        #expect(again == .alreadyCompleted)
    }

    @Test func confirmedRouteCoordinatesRemainUnchangedAfterExecution() throws {
        let input = try makeExecutionInput()
        let originalCoordinates = input.route.coordinates

        var engine = ExecutionEngine(input: input)
        _ = engine.start()
        _ = engine.runToCompletion()

        #expect(engine.input.route.coordinates == originalCoordinates)
        #expect(input.route.coordinates == originalCoordinates)
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
