//
//  ExecutionInput.swift
//  delivery-game
//

import Foundation

/// Immutable hand-off from planning into execution.
///
/// Created only by successful route confirmation. Execution must start from
/// this value and must not re-read mutable planning state.
nonisolated struct ExecutionInput: Equatable, Sendable {
    let jobID: SeededJobID
    let jobDisplayName: String
    let targetTimeMinutes: Int
    let deadlineMinutes: Int
    let economy: EconomyConfiguration
    /// Full ordered route including the depot.
    let route: Route
    /// Card types for every entered coordinate after the depot, in route order.
    let enteredCardTypes: [CardType]

    var enteredCoordinates: [GridCoordinate] {
        Array(route.coordinates.dropFirst())
    }
}
