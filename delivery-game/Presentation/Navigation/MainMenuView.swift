//
//  MainMenuView.swift
//  delivery-game
//

import SwiftUI

/// Prototype main menu. Independent of the grid; only emits a start action.
struct MainMenuView: View {
    let onStartGame: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(GridPalette.accent)

                Text("Courier's Gambit")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(GridPalette.ink)

                Text("Plan the route. Beat the clock.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(GridPalette.mutedInk)
            }

            Button(action: onStartGame) {
                Text("Start Game")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(GridPalette.canvas)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(GridPalette.accent)
                    )
            }
            .accessibilityIdentifier(GridAccessibilityID.startGameButton)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GridPalette.canvas.ignoresSafeArea())
        .accessibilityIdentifier(GridAccessibilityID.mainMenu)
    }
}

#Preview {
    MainMenuView(onStartGame: {})
}
