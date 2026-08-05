//
//  RouteValidationStatusView.swift
//  delivery-game
//

import SwiftUI

/// Displays route completion status from a validation result.
/// Independent of route-building logic and navigation.
struct RouteValidationStatusView: View {
    let validation: RouteValidationResult

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: validation.isComplete ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(validation.isComplete ? GridPalette.depot : GridPalette.mutedInk)

            Text(message)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(validation.isComplete ? GridPalette.depot : GridPalette.mutedInk)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GridPalette.panel)
        )
        .accessibilityIdentifier(GridAccessibilityID.routeValidationStatus)
        .accessibilityLabel(message)
    }

    private var message: String {
        validation.isComplete
            ? "Route complete — ready to confirm"
            : "Route incomplete — reach the destination"
    }
}

#Preview("Incomplete") {
    RouteValidationStatusView(
        validation: RouteValidator.validate(
            route: Route(coordinates: [.depot, GridCoordinate(row: 0, column: 1)])
        )
    )
    .padding()
    .background(GridPalette.canvas)
}

#Preview("Complete") {
    RouteValidationStatusView(
        validation: RouteValidator.validate(route: Route(coordinates: [.depot, .destination]))
    )
    .padding()
    .background(GridPalette.canvas)
}
