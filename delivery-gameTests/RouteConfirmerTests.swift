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

        guard case .rejected(let reason) = result else {
            Issue.record("Expected incomplete route to be rejected")
            return
        }
        #expect(reason == .routeIncomplete)
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
        #expect(input.jobDisplayName == job.displayName)
        #expect(input.targetTimeMinutes == job.targetTimeMinutes)
        #expect(input.deadlineMinutes == job.deadlineMinutes)
        #expect(input.route.coordinates.count == route.coordinates.count)
        #expect(input.route.endpoint == .destination)
        #expect(input.enteredCardTypes.count == input.enteredCoordinates.count)
        #expect(input.enteredCoordinates.count == route.coordinates.count - 1)

        for (coordinate, cardType) in zip(input.enteredCoordinates, input.enteredCardTypes) {
            #expect(grid.cardType(at: coordinate) == cardType)
        }
    }

    @Test func preventsDuplicateTransitionsWhenAlreadyConfirmed() throws {
        let (job, grid, route) = try makeCompleteRoute()

        let first = RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: false
        )
        guard case .confirmed = first else {
            Issue.record("Expected first confirmation to succeed")
            return
        }

        let duplicate = RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: true
        )
        guard case .rejected(let reason) = duplicate else {
            Issue.record("Expected duplicate confirmation to be rejected")
            return
        }
        #expect(reason == .alreadyConfirmed)
    }

    @Test func confirmedInputUsesCompleteRouteOnly() throws {
        let (job, grid, route) = try makeCompleteRoute()
        var builder = RouteBuilder()
        _ = builder.select(GridCoordinate(row: 0, column: 1))

        let incompleteResult = RouteConfirmer.confirm(
            route: builder.route,
            job: job,
            grid: grid,
            alreadyConfirmed: false
        )
        guard case .rejected = incompleteResult else {
            Issue.record("Expected incomplete route rejection")
            return
        }

        let completeResult = RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: false
        )
        guard case .confirmed(let input) = completeResult else {
            Issue.record("Expected complete route confirmation")
            return
        }

        #expect(RouteValidator.validate(route: input.route).canConfirm)
        #expect(input.enteredCardTypes.isEmpty == false)
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
