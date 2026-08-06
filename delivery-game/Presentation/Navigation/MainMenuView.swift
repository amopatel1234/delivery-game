//
//  MainMenuView.swift
//  delivery-game
//

import SwiftUI

/// Prototype main menu. Independent of the grid; only emits a start action.
struct MainMenuView: View {
    let onStartGame: () -> Void
    var showsResetOnboarding: Bool = false
    var onResetOnboarding: (() -> Void)?

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(GridPalette.accent)
                    .accessibilityHidden(true)

                Text("Couriers Gambit")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(GridPalette.ink)

                Text("Plan the route. Beat the clock.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(GridPalette.mutedInk)
                    .multilineTextAlignment(.center)
            }

            Button(action: onStartGame) {
                Text(AccessibilityCopy.startGameLabel)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(GridPalette.canvas)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(GridPalette.accent)
                    )
            }
            .accessibilityIdentifier(GridAccessibilityID.startGameButton)
            .accessibilityLabel(AccessibilityCopy.startGameLabel)
            .accessibilityHint(AccessibilityCopy.startGameHint)

            if showsResetOnboarding, let onResetOnboarding {
                Button("Reset Onboarding", action: onResetOnboarding)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(GridPalette.mutedInk)
                    .accessibilityIdentifier(GridAccessibilityID.resetOnboardingButton)
                    .accessibilityLabel("Reset onboarding")
                    .accessibilityHint("Clears How to Play completion so it appears again.")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GridPalette.canvas.ignoresSafeArea())
        .accessibilityIdentifier(GridAccessibilityID.mainMenu)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}

#Preview {
    MainMenuView(onStartGame: {}, showsResetOnboarding: true, onResetOnboarding: {})
}
