//
//  ExecutionHandoffView.swift
//  delivery-game
//

import SwiftUI

/// Placeholder execution surface that accepts only a confirmed route input.
/// Full resolution belongs to Epic 3.
struct ExecutionHandoffView: View {
    let input: ExecutionInput

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Route confirmed")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(GridPalette.ink)

            Text(input.jobDisplayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GridPalette.mutedInk)

            Text(
                "Execution is locked to this route · \(input.enteredCoordinates.count) cards after Depot"
            )
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(GridPalette.mutedInk)

            Text("Simulation starts in a later update.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(GridPalette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GridPalette.panel)
        )
        .accessibilityIdentifier(GridAccessibilityID.executionHandoff)
        .accessibilityLabel(
            "Route confirmed for \(input.jobDisplayName). Execution locked to \(input.enteredCoordinates.count) cards after Depot."
        )
    }
}

#Preview {
    let job = try! SeededJobCatalogue.loadDefault()
    let grid = try! DeliveryGrid(board: job.board)
    let route = Route(coordinates: [
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
    let result = RouteConfirmer.confirm(
        route: route,
        job: job,
        grid: grid,
        alreadyConfirmed: false
    )
    if case .confirmed(let input) = result {
        ExecutionHandoffView(input: input)
            .padding()
            .background(GridPalette.canvas)
    }
}
