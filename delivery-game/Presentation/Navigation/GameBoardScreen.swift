//
//  GameBoardScreen.swift
//  delivery-game
//

import SwiftUI

/// Thin screen that loads a seeded job and hosts route construction.
/// Owns screen state; reusable grid/undo views stay free of route rules.
struct GameBoardScreen: View {
    let jobID: SeededJobID

    @State private var grid: DeliveryGrid?
    @State private var routeBuilder = RouteBuilder()
    @State private var loadErrorMessage: String?
    @State private var rejectionMessage: String?

    init(jobID: SeededJobID = SeededJobCatalogue.defaultJobID) {
        self.jobID = jobID
    }

    var body: some View {
        Group {
            if let grid {
                VStack(spacing: 16) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(GridPalette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(statusText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(rejectionMessage == nil ? GridPalette.mutedInk : GridPalette.destination)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("route-status")

                    RouteValidationStatusView(
                        validation: RouteValidator.validate(route: routeBuilder.route)
                    )

                    GridBoardView(
                        grid: grid,
                        selectedCoordinates: Set(routeBuilder.selectedCoordinates),
                        endpoint: routeBuilder.endpoint,
                        onSelect: handleSelection
                    )
                    .aspectRatio(1, contentMode: .fit)

                    RouteUndoButton(
                        isEnabled: routeBuilder.canUndo,
                        action: handleUndo
                    )

                    Spacer(minLength: 0)
                }
                .padding(16)
            } else if let loadErrorMessage {
                Text(loadErrorMessage)
                    .foregroundStyle(GridPalette.destination)
                    .padding()
            } else {
                ProgressView()
                    .tint(GridPalette.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GridPalette.canvas.ignoresSafeArea())
        .navigationTitle("Board")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: jobID) {
            loadBoard()
        }
    }

    private var title: String {
        SeededJobCatalogue.definition(for: jobID).displayName
    }

    private var statusText: String {
        if let rejectionMessage {
            return rejectionMessage
        }
        let steps = max(routeBuilder.selectedCoordinates.count - 1, 0)
        return "Route started at Depot · \(steps) step\(steps == 1 ? "" : "s")"
    }

    private func loadBoard() {
        do {
            let job = try SeededJobCatalogue.load(id: jobID)
            grid = try DeliveryGrid(board: job.board)
            routeBuilder = RouteBuilder()
            rejectionMessage = nil
            loadErrorMessage = nil
        } catch {
            grid = nil
            loadErrorMessage = "Could not load board."
        }
    }

    private func handleSelection(_ coordinate: GridCoordinate) {
        switch routeBuilder.select(coordinate) {
        case .accepted:
            rejectionMessage = nil
        case .rejected(let reason):
            rejectionMessage = feedback(for: reason)
        }
    }

    private func handleUndo() {
        switch routeBuilder.undo() {
        case .undone:
            rejectionMessage = nil
        case .atDepot:
            rejectionMessage = "Route is already back at the Depot."
        }
    }

    private func feedback(for reason: RouteRejectionReason) -> String {
        switch reason {
        case .notOrthogonallyAdjacent:
            "Invalid move: choose a card beside the route end."
        case .alreadyVisited:
            "Invalid move: that card is already on the route."
        case .outOfBounds:
            "Invalid move: that card is off the board."
        }
    }
}

#Preview {
    NavigationStack {
        GameBoardScreen()
    }
}
