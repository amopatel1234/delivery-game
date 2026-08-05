//
//  RouteValidatorTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct RouteValidatorTests {

    @Test func depotOnlyRouteIsIncomplete() {
        let result = RouteValidator.validate(route: Route(coordinates: [.depot]))

        #expect(result.state == .incomplete)
        #expect(!result.isComplete)
        #expect(!result.canConfirm)
        #expect(result.endpoint == .depot)
        #expect(result.destination == .destination)
    }

    @Test func partialRouteEndingBeforeDestinationIsIncomplete() {
        let partial = Route(coordinates: [
            .depot,
            GridCoordinate(row: 0, column: 1),
            GridCoordinate(row: 0, column: 2),
            GridCoordinate(row: 1, column: 2),
        ])
        let result = RouteValidator.validate(route: partial)

        #expect(result.state == .incomplete)
        #expect(!result.canConfirm)
        #expect(result.endpoint != .destination)
    }

    @Test func routeEndingAtDestinationIsComplete() {
        let complete = Route(coordinates: [
            .depot,
            GridCoordinate(row: 0, column: 1),
            GridCoordinate(row: 0, column: 2),
            GridCoordinate(row: 0, column: 3),
            GridCoordinate(row: 0, column: 4),
            GridCoordinate(row: 1, column: 4),
            GridCoordinate(row: 2, column: 4),
            GridCoordinate(row: 3, column: 4),
            .destination,
        ])
        let result = RouteValidator.validate(route: complete)

        #expect(result.state == .complete)
        #expect(result.isComplete)
        #expect(result.canConfirm)
        #expect(result.endpoint == .destination)
    }

    @Test func routeVisitingDestinationBeforeEndpointIsIncomplete() {
        let route = Route(coordinates: [
            .depot,
            GridCoordinate(row: 0, column: 1),
            .destination,
            GridCoordinate(row: 3, column: 4),
        ])
        let result = RouteValidator.validate(route: route)

        #expect(result.state == .incomplete)
        #expect(!result.canConfirm)
        #expect(result.endpoint == GridCoordinate(row: 3, column: 4))
    }

    @Test func validationUpdatesAfterBuilderSelectionAndUndo() {
        var builder = RouteBuilder()
        var validation = RouteValidator.validate(route: builder.route)
        #expect(!validation.canConfirm)

        _ = builder.select(GridCoordinate(row: 0, column: 1))
        validation = RouteValidator.validate(route: builder.route)
        #expect(!validation.canConfirm)

        _ = builder.undo()
        validation = RouteValidator.validate(route: builder.route)
        #expect(validation.endpoint == .depot)
        #expect(!validation.canConfirm)
    }
}
