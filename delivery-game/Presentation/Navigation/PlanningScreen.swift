//
//  PlanningScreen.swift
//  delivery-game
//

import SwiftUI

/// Integrated planning experience: grid, route editing, validation, summary and confirm state.
struct PlanningScreen: View {
    let jobID: SeededJobID

    @State private var job: SeededJob?
    @State private var grid: DeliveryGrid?
    @State private var routeBuilder = RouteBuilder()
    @State private var loadErrorMessage: String?
    @State private var rejectionMessage: String?
    @State private var confirmMessage: String?

    init(jobID: SeededJobID = SeededJobCatalogue.defaultJobID) {
        self.jobID = jobID
    }

    private var validation: RouteValidationResult {
        RouteValidator.validate(route: routeBuilder.route)
    }

    private var summary: PlanningSummaryInput {
        guard let job, let grid else {
            return PlanningSummaryInput(
                targetTimeMinutes: 0,
                deadlineMinutes: 0,
                estimatedArrivalMinutes: nil,
                delayExposure: nil,
                damageRisk: nil,
                maximumReward: nil
            )
        }
        return PlanningSummaryInput.from(
            job: job,
            route: routeBuilder.route,
            grid: grid
        )
    }

    var body: some View {
        Group {
            if let grid, let job {
                ScrollView {
                    VStack(spacing: 16) {
                        Text(job.displayName)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(GridPalette.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(routeStatusText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(statusColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("route-status")

                        RouteValidationStatusView(validation: validation)

                        GridBoardView(
                            grid: grid,
                            selectedCoordinates: Set(routeBuilder.selectedCoordinates),
                            endpoint: routeBuilder.endpoint,
                            onSelect: handleSelection
                        )
                        .aspectRatio(1, contentMode: .fit)

                        PlanningSummaryView(summary: summary)

                        RouteUndoButton(
                            isEnabled: routeBuilder.canUndo,
                            action: handleUndo
                        )

                        RouteConfirmButton(
                            isEnabled: validation.canConfirm,
                            action: handleConfirm
                        )

                        if let confirmMessage {
                            Text(confirmMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(GridPalette.mutedInk)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityIdentifier("route-confirm-message")
                        }
                    }
                    .padding(16)
                }
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
        .navigationTitle("Planning")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: jobID) {
            loadJob()
        }
    }

    private var routeStatusText: String {
        if let rejectionMessage {
            return rejectionMessage
        }
        if let confirmMessage {
            return confirmMessage
        }
        let steps = max(routeBuilder.selectedCoordinates.count - 1, 0)
        return "Route started at Depot · \(steps) step\(steps == 1 ? "" : "s")"
    }

    private var statusColor: Color {
        if rejectionMessage != nil {
            return GridPalette.destination
        }
        return GridPalette.mutedInk
    }

    private func loadJob() {
        do {
            let loadedJob = try SeededJobCatalogue.load(id: jobID)
            job = loadedJob
            grid = try DeliveryGrid(board: loadedJob.board)
            routeBuilder = RouteBuilder()
            rejectionMessage = nil
            confirmMessage = nil
            loadErrorMessage = nil
        } catch {
            job = nil
            grid = nil
            loadErrorMessage = "Could not load job."
        }
    }

    private func handleSelection(_ coordinate: GridCoordinate) {
        switch routeBuilder.select(coordinate) {
        case .accepted:
            rejectionMessage = nil
            confirmMessage = nil
        case .rejected(let reason):
            rejectionMessage = feedback(for: reason)
        }
    }

    private func handleUndo() {
        switch routeBuilder.undo() {
        case .undone:
            rejectionMessage = nil
            confirmMessage = nil
        case .atDepot:
            rejectionMessage = "Route is already back at the Depot."
        }
    }

    private func handleConfirm() {
        guard validation.canConfirm else { return }
        // Confirmation transition is implemented in a later story.
        confirmMessage = "Route ready to confirm. Execution starts in a later update."
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
        PlanningScreen()
    }
}
