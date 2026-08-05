//
//  ExecutionHandoffView.swift
//  delivery-game
//

import SwiftUI

/// Confirmed-route handoff surface. Hosts live execution presentation when available.
struct ExecutionHandoffView: View {
    let input: ExecutionInput
    var presentation: ExecutionPresentationState?

    var body: some View {
        if let presentation {
            ExecutionProgressView(presentation: presentation)
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
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
