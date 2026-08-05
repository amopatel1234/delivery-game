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
    let route: Route
    let grid: DeliveryGrid
    let analysis: PlanningAnalysisResult
    let summary: PlanningSummaryInput

    /// Ordered entered cards after the depot, matching analysis traversal.
    var enteredCoordinates: [GridCoordinate] {
        Array(route.coordinates.dropFirst())
    }
}
