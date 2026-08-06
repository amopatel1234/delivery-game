//
//  RouteUndoButton.swift
//  delivery-game
//

import SwiftUI

/// Standalone undo control. Enabled state and action are injected by the host screen.
struct RouteUndoButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Undo", systemImage: "arrow.uturn.backward")
                .font(.headline.weight(.semibold))
                .foregroundStyle(isEnabled ? GridPalette.canvas : GridPalette.mutedInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isEnabled ? GridPalette.accent : GridPalette.panel)
                )
        }
        .disabled(!isEnabled)
        .accessibilityIdentifier(GridAccessibilityID.undoButton)
        .accessibilityLabel(AccessibilityCopy.undoLabel)
        .accessibilityHint(isEnabled ? AccessibilityCopy.undoHint : AccessibilityCopy.undoDisabledHint)
    }
}

#Preview("Enabled") {
    RouteUndoButton(isEnabled: true, action: {})
        .padding()
        .background(GridPalette.canvas)
}

#Preview("Disabled") {
    RouteUndoButton(isEnabled: false, action: {})
        .padding()
        .background(GridPalette.canvas)
}
