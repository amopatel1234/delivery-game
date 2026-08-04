//
//  RootNavigationView.swift
//  delivery-game
//

import SwiftUI

/// App shell: Main Menu → Start Game → board screen.
struct RootNavigationView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            MainMenuView {
                path.append(AppRoute.gameBoard)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .gameBoard:
                    GameBoardScreen()
                }
            }
        }
        .tint(GridPalette.accent)
    }
}

#Preview {
    RootNavigationView()
}
