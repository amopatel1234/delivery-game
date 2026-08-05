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

        #expect(rejectionReason(result) == .routeIncomplete)
    }

    @Test func confirmsOnlyCompleteRoutes() throws {
        let (job, grid, route) = try makeCompleteRoute()

        let result = RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: false
        )

        guard let input = confirmedInput(result) else {
            Issue.record("Expected confirmation to succeed")
            return
        }

        #expect(input.jobID == job.id)
        #expect(input.route.coordinates == route.coordinates)
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

        guard let firstInput = confirmedInput(first),
              let secondInput = confirmedInput(second) else {
            Issue.record("Expected both confirmations to succeed")
            return
        }

        #expect(firstInput.jobID == secondInput.jobID)
        #expect(firstInput.route.coordinates == secondInput.route.coordinates)
        #expect(
            firstInput.analysis.estimatedArrivalMinutes
                == secondInput.analysis.estimatedArrivalMinutes
        )
        #expect(firstInput.summary.maximumReward == secondInput.summary.maximumReward)

        var otherBuilder = RouteBuilder()
        _ = otherBuilder.select(GridCoordinate(row: 1, column: 0))
        #expect(firstInput.route.endpoint == .destination)
        #expect(firstInput.route.coordinates != otherBuilder.route.coordinates)
    }

    @Test func preventsDuplicateTransitionsWhenAlreadyConfirmed() throws {
        let (job, grid, route) = try makeCompleteRoute()

        let first = RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: false
        )
        guard confirmedInput(first) != nil else {
            Issue.record("Expected first confirmation to succeed")
            return
        }

        let duplicate = RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: true
        )
        #expect(rejectionReason(duplicate) == .alreadyConfirmed)
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

        #expect(rejectionReason(rejected) == .routeIncomplete)

        guard let input = confirmedInput(accepted) else {
            Issue.record("Expected confirmation to succeed")
            return
        }
        #expect(input.route.coordinates == route.coordinates)
        #expect(RouteValidator.validate(route: input.route).canConfirm)
    }

    @Test func editingLockStateFollowsConfirmationFlag() throws {
        let (job, grid, route) = try makeCompleteRoute()
        var didConfirm = false

        switch RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: false
        ) {
        case .confirmed:
            didConfirm = true
        case .rejected:
            Issue.record("Expected first confirmation to succeed")
        }

        #expect(didConfirm)

        let locked = RouteConfirmer.confirm(
            route: route,
            job: job,
            grid: grid,
            alreadyConfirmed: true
        )
        #expect(rejectionReason(locked) == .alreadyConfirmed)
    }

    private func rejectionReason(
        _ result: RouteConfirmationResult
    ) -> RouteConfirmationRejection? {
        if case .rejected(let reason) = result {
            return reason
        }
        return nil
    }

    private func confirmedInput(
        _ result: RouteConfirmationResult
    ) -> ExecutionInput? {
        if case .confirmed(let input) = result {
            return input
        }
        return nil
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
