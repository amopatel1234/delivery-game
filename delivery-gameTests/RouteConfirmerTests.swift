//
//  RouteConfirmerTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct RouteConfirmerTests {

    @Test func rejectsIncompleteRoutes() throws {
        let job = try SeededJobCatalogue.loadDefault()
        let grid = try DeliveryGrid(board: job.board)
        var builder = RouteBuilder()
        _ = builder.select(GridCoordinate(row: 0, column: 1))

        let result = RouteConfirmer.confirm(
            route: builder.route,
            job: job,
            grid: grid,
            alreadyConfirmed: false
        )

        #expect(result == .rejected(.routeIncomplete))
    }

    @Test func confirmsOnlyCompleteRoutes() throws {
        let (job, grid, route) = try makeCompleteRoute()

        let result = RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: false
        )

        guard case .confirmed(let input) = result else {
            Issue.record("Expected confirmation to succeed")
            return
        }

        #expect(input.jobID == job.id)
        #expect(input.route == route)
        #expect(input.route.endpoint == .destination)
        #expect(input.enteredCoordinates.count == route.coordinates.count - 1)
        #expect(input.summary.estimatedArrivalMinutes != nil)
        #expect(input.analysis.enteredSegments.count == input.enteredCoordinates.count)
    }

    @Test func createsImmutableExecutionInputSnapshot() throws {
        let (job, grid, route) = try makeCompleteRoute()

        let first = RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: false
        )
        let second = RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: false
        )

        #expect(first == second)
        guard case .confirmed(let input) = first else {
            Issue.record("Expected confirmation to succeed")
            return
        }

        // Snapshot remains equal after unrelated route mutations elsewhere.
        var otherBuilder = RouteBuilder()
        _ = otherBuilder.select(GridCoordinate(row: 1, column: 0))
        #expect(input.route.endpoint == .destination)
        #expect(input.route != otherBuilder.route)
    }

    @Test func preventsDuplicateTransitionsWhenAlreadyConfirmed() throws {
        let (job, grid, route) = try makeCompleteRoute()

        let first = RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: false
        )
        #expect({
            if case .confirmed = first { return true }
            return false
        }())

        let duplicate = RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: true
        )
        #expect(duplicate == .rejected(.alreadyConfirmed))
    }

    @Test func executionInputStartsFromConfirmedRouteOnly() throws {
        let (job, grid, route) = try makeCompleteRoute()
        let incomplete = Route(coordinates: [.depot, GridCoordinate(row: 0, column: 1)])

        let rejected = RouteConfirmer.confirm(
            route: incomplete,
            job: job,
            grid: grid,
            alreadyConfirmed: false
        )
        let accepted = RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: false
        )

        #expect(rejected == .rejected(.routeIncomplete))
        guard case .confirmed(let input) = accepted else {
            Issue.record("Expected confirmation to succeed")
            return
        }
        #expect(input.route == route)
        #expect(RouteValidator.validate(route: input.route).canConfirm)
    }

    @Test func editingLockStateFollowsConfirmationFlag() throws {
        // Mirrors PlanningScreen: once confirmed, further confirms are rejected
        // and editing must remain locked by the caller.
        let (job, grid, route) = try makeCompleteRoute()
        var confirmed: ExecutionInput?
        var alreadyConfirmed = false

        switch RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: alreadyConfirmed
        ) {
        case .confirmed(let input):
            confirmed = input
            alreadyConfirmed = true
        case .rejected:
            Issue.record("Expected first confirmation to succeed")
        }

        #expect(confirmed != nil)
        #expect(alreadyConfirmed)

        let locked = RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: alreadyConfirmed
        )
        #expect(locked == .rejected(.alreadyConfirmed))
    }

    private func makeCompleteRoute() throws -> (SeededJob, DeliveryGrid, Route) {
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
        return (job, grid, builder.route)
    }
}
