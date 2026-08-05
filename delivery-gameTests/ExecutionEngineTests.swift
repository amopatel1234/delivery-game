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
        #expect(firstState.elapsedMinutes == 0)
        #expect(firstState.damageEventCount == 0)

        for (lhs, rhs) in zip(firstState.resolvedSteps, secondState.resolvedSteps) {
            #expect(lhs.enteredIndex == rhs.enteredIndex)
            #expect(lhs.coordinate == rhs.coordinate)
            #expect(lhs.cardType == rhs.cardType)
        }
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

    private func makeExecutionInput() throws -> ExecutionInput {
        let job = try SeededJobCatalogue.loadDefault()
        let grid = try DeliveryGrid(board: job.board)
        var builder = RouteBuilder()
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
                enteredCardTypes: []
            )
        }
        return input
    }
}
