//
//  RouteValidator.swift
//  delivery-game
//

import Foundation

/// Whether the current route has reached the destination endpoint.
nonisolated enum RouteCompletionState: Equatable, Sendable {
    case incomplete
    case complete
}

/// Presentation-independent route validation output.
nonisolated struct RouteValidationResult: Equatable, Sendable {
    let state: RouteCompletionState
    let endpoint: GridCoordinate
    let destination: GridCoordinate

    var isComplete: Bool {
        state == .complete
    }

    /// True only when the route endpoint is the destination.
    var canConfirm: Bool {
        isComplete
    }
}

/// Validates whether a route is complete and eligible for confirmation.
nonisolated enum RouteValidator {
    static func validate(
        route: Route,
        destination: GridCoordinate = .destination
    ) -> RouteValidationResult {
        let state: RouteCompletionState = route.endpoint == destination ? .complete : .incomplete
        return RouteValidationResult(
            state: state,
            endpoint: route.endpoint,
            destination: destination
        )
    }
}
