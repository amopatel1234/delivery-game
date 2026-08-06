//
//  RootNavigationView.swift
//  delivery-game
//

import SwiftUI

/// App shell: Main Menu → Start Game → planning screen.
struct RootNavigationView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            MainMenuView {
                path.append(AppRoute.planning)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .planning:
                    PlanningScreen { input in
                        path.append(AppRoute.results(input))
                    }
                case .results(let input):
                    ResultsScreenView(input: input) {
                        path = NavigationPath()
                    }
                }
            }
        }
        .tint(GridPalette.accent)
    }
}

#Preview {
    RootNavigationView()
}
