//
//  RouteBuilder.swift
//  delivery-game
//

import Foundation

extension GridCoordinate {
    /// True when the other coordinate shares an edge (not a corner).
    func isOrthogonallyAdjacent(to other: GridCoordinate) -> Bool {
        let rowDistance = abs(row - other.row)
        let columnDistance = abs(column - other.column)
        return rowDistance + columnDistance == 1
    }
}

/// Ordered route from depot through selected grid coordinates.
nonisolated struct Route: Equatable, Sendable {
    let coordinates: [GridCoordinate]

    var endpoint: GridCoordinate {
        guard let endpoint = coordinates.last else {
            preconditionFailure("Route must always contain at least the depot")
        }
        return endpoint
    }

    var depot: GridCoordinate {
        guard let depot = coordinates.first else {
            preconditionFailure("Route must always contain at least the depot")
        }
        return depot
    }

    var visitedCoordinates: Set<GridCoordinate> {
        Set(coordinates)
    }

    func contains(_ coordinate: GridCoordinate) -> Bool {
        coordinates.contains(coordinate)
    }
}

/// Why a tap/selection was rejected by the route builder.
nonisolated enum RouteRejectionReason: Equatable, Sendable {
    case notOrthogonallyAdjacent
    case alreadyVisited
    case outOfBounds
}

/// Result of attempting to extend the route.
nonisolated enum RouteSelectionResult: Equatable, Sendable {
    case accepted(Route)
    case rejected(RouteRejectionReason)
}

/// Result of attempting to undo the latest route step.
nonisolated enum RouteUndoResult: Equatable, Sendable {
    case undone(Route)
    /// Depot is the minimum route state and cannot be removed.
    case atDepot
}

/// Pure domain route construction. Starts at the depot and grows by orthogonal moves.
nonisolated struct RouteBuilder: Equatable, Sendable {
    private(set) var route: Route

    init(startingAt depot: GridCoordinate = .depot) {
        precondition(depot == .depot, "Routes must start at the depot")
        self.route = Route(coordinates: [depot])
    }

    var endpoint: GridCoordinate { route.endpoint }

    var selectedCoordinates: [GridCoordinate] { route.coordinates }

    /// True when at least one non-depot step can be removed.
    var canUndo: Bool {
        route.coordinates.count > 1
    }

    /// Attempts to append `coordinate` when it is a legal next step.
    mutating func select(_ coordinate: GridCoordinate) -> RouteSelectionResult {
        if !coordinate.isOnBoard {
            return .rejected(.outOfBounds)
        }

        if route.contains(coordinate) {
            return .rejected(.alreadyVisited)
        }

        if !route.endpoint.isOrthogonallyAdjacent(to: coordinate) {
            return .rejected(.notOrthogonallyAdjacent)
        }

        route = Route(coordinates: route.coordinates + [coordinate])
        return .accepted(route)
    }

    /// Removes only the most recently selected card. Never removes the depot.
    @discardableResult
    mutating func undo() -> RouteUndoResult {
        guard canUndo else {
            return .atDepot
        }

        var coordinates = route.coordinates
        coordinates.removeLast()
        route = Route(coordinates: coordinates)
        return .undone(route)
    }
}
