//
//  RouteBuilderTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct RouteBuilderTests {

    @Test func startsEveryRouteAtTheDepot() {
        let builder = RouteBuilder()
        #expect(builder.route.coordinates == [.depot])
        #expect(builder.endpoint == .depot)
        #expect(builder.route.depot == .depot)
    }

    @Test func addsOnlyOrthogonallyAdjacentCards() {
        var builder = RouteBuilder()

        let right = GridCoordinate(row: 0, column: 1)
        let downFromRight = GridCoordinate(row: 1, column: 1)

        #expect(builder.select(right) == .accepted(Route(coordinates: [.depot, right])))
        #expect(
            builder.select(downFromRight)
                == .accepted(Route(coordinates: [.depot, right, downFromRight]))
        )
    }

    @Test func rejectsDiagonalMoves() {
        var builder = RouteBuilder()
        let diagonal = GridCoordinate(row: 1, column: 1)

        #expect(builder.select(diagonal) == .rejected(.notOrthogonallyAdjacent))
        #expect(builder.route.coordinates == [.depot])
    }

    @Test func rejectsNonAdjacentMoves() {
        var builder = RouteBuilder()
        let far = GridCoordinate(row: 0, column: 2)

        #expect(builder.select(far) == .rejected(.notOrthogonallyAdjacent))
        #expect(builder.route.coordinates == [.depot])
    }

    @Test func rejectsPreviouslyVisitedCards() {
        var builder = RouteBuilder()
        let right = GridCoordinate(row: 0, column: 1)

        #expect(builder.select(right) == .accepted(Route(coordinates: [.depot, right])))
        #expect(builder.select(.depot) == .rejected(.alreadyVisited))
        #expect(builder.select(right) == .rejected(.alreadyVisited))
        #expect(builder.route.coordinates == [.depot, right])
    }

    @Test func rejectsOutOfBoundsCoordinates() {
        var builder = RouteBuilder()
        let offBoard = GridCoordinate(row: -1, column: 0)

        #expect(builder.select(offBoard) == .rejected(.outOfBounds))
        #expect(builder.route.coordinates == [.depot])
    }

    @Test func preservesSelectedRouteOrder() {
        var builder = RouteBuilder()
        let path = [
            GridCoordinate(row: 0, column: 1),
            GridCoordinate(row: 0, column: 2),
            GridCoordinate(row: 1, column: 2),
            GridCoordinate(row: 1, column: 1),
        ]

        for coordinate in path {
            let result = builder.select(coordinate)
            guard case .accepted = result else {
                Issue.record("Expected accepted selection for \(coordinate)")
                return
            }
        }

        #expect(builder.selectedCoordinates == [.depot] + path)
        #expect(builder.endpoint == path.last)
    }

    @Test func adjacencyHelperDetectsOrthogonalNeighborsOnly() {
        let origin = GridCoordinate(row: 2, column: 2)

        #expect(origin.isOrthogonallyAdjacent(to: GridCoordinate(row: 2, column: 3)))
        #expect(origin.isOrthogonallyAdjacent(to: GridCoordinate(row: 1, column: 2)))
        #expect(!origin.isOrthogonallyAdjacent(to: GridCoordinate(row: 1, column: 1)))
        #expect(!origin.isOrthogonallyAdjacent(to: GridCoordinate(row: 2, column: 2)))
        #expect(!origin.isOrthogonallyAdjacent(to: GridCoordinate(row: 2, column: 4)))
    }

    @Test func undoRemovesOnlyMostRecentCard() {
        var builder = RouteBuilder()
        let right = GridCoordinate(row: 0, column: 1)
        let down = GridCoordinate(row: 1, column: 1)

        _ = builder.select(right)
        _ = builder.select(down)

        #expect(builder.undo() == .undone(Route(coordinates: [.depot, right])))
        #expect(builder.endpoint == right)
        #expect(builder.selectedCoordinates == [.depot, right])
    }

    @Test func repeatedUndoStopsAtDepotAndNeverRemovesIt() {
        var builder = RouteBuilder()
        let path = [
            GridCoordinate(row: 0, column: 1),
            GridCoordinate(row: 0, column: 2),
            GridCoordinate(row: 1, column: 2),
        ]

        for coordinate in path {
            _ = builder.select(coordinate)
        }

        #expect(builder.canUndo)
        #expect(builder.undo() == .undone(Route(coordinates: [.depot, path[0], path[1]])))
        #expect(builder.undo() == .undone(Route(coordinates: [.depot, path[0]])))
        #expect(builder.undo() == .undone(Route(coordinates: [.depot])))
        #expect(builder.undo() == .atDepot)
        #expect(builder.undo() == .atDepot)
        #expect(!builder.canUndo)
        #expect(builder.route.coordinates == [.depot])
        #expect(builder.endpoint == .depot)
    }

    @Test func undoPreservesValidOrderedRoute() {
        var builder = RouteBuilder()
        let right = GridCoordinate(row: 0, column: 1)
        let farther = GridCoordinate(row: 0, column: 2)

        _ = builder.select(right)
        _ = builder.select(farther)
        _ = builder.undo()

        #expect(builder.selectedCoordinates == [.depot, right])
        #expect(builder.select(farther) == .accepted(Route(coordinates: [.depot, right, farther])))
    }
}
