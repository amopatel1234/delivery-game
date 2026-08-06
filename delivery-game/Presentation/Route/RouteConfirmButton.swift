//
//  RouteConfirmButton.swift
//  delivery-game
//

import SwiftUI

/// Standalone confirm control. Enabled only when the route is complete.
struct RouteConfirmButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Confirm Route", systemImage: "checkmark.circle.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(isEnabled ? GridPalette.canvas : GridPalette.mutedInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isEnabled ? GridPalette.depot : GridPalette.panel)
                )
        }
        .disabled(!isEnabled)
        .accessibilityIdentifier(GridAccessibilityID.confirmRouteButton)
        .accessibilityLabel(AccessibilityCopy.confirmLabel)
        .accessibilityHint(isEnabled ? AccessibilityCopy.confirmHint : AccessibilityCopy.confirmDisabledHint)
    }
}

#Preview("Enabled") {
    RouteConfirmButton(isEnabled: true, action: {})
        .padding()
        .background(GridPalette.canvas)
}

#Preview("Disabled") {
    RouteConfirmButton(isEnabled: false, action: {})
        .padding()
        .background(GridPalette.canvas)
}
