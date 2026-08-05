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
    @State private var executionInput: ExecutionInput?
    @State private var loadErrorMessage: String?
    @State private var rejectionMessage: String?

    init(jobID: SeededJobID = SeededJobCatalogue.defaultJobID) {
        self.jobID = jobID
    }

    private var isEditingLocked: Bool {
        executionInput != nil
    }

    private var validation: RouteValidationResult {
        RouteValidator.validate(route: routeBuilder.route)
    }

    private var summary: PlanningSummaryInput {
        if let executionInput {
            return executionInput.summary
        }
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
                            onSelect: isEditingLocked ? nil : handleSelection
                        )
                        .aspectRatio(1, contentMode: .fit)
                        .allowsHitTesting(!isEditingLocked)

                        PlanningSummaryView(summary: summary)

                        if let executionInput {
                            ExecutionHandoffView(input: executionInput)
                        }

                        RouteUndoButton(
                            isEnabled: !isEditingLocked && routeBuilder.canUndo,
                            action: handleUndo
                        )

                        RouteConfirmButton(
                            isEnabled: !isEditingLocked && validation.canConfirm,
                            action: handleConfirm
                        )
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
        if isEditingLocked {
            return "Route confirmed · editing locked"
        }
        if let rejectionMessage {
            return rejectionMessage
        }
        let steps = max(routeBuilder.selectedCoordinates.count - 1, 0)
        return "Route started at Depot · \(steps) step\(steps == 1 ? "" : "s")"
    }

    private var statusColor: Color {
        if isEditingLocked {
            return GridPalette.depot
        }
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
            executionInput = nil
            rejectionMessage = nil
            loadErrorMessage = nil
        } catch {
            job = nil
            grid = nil
            executionInput = nil
            loadErrorMessage = "Could not load job."
        }
    }

    private func handleSelection(_ coordinate: GridCoordinate) {
        guard !isEditingLocked else { return }
        switch routeBuilder.select(coordinate) {
        case .accepted:
            rejectionMessage = nil
        case .rejected(let reason):
            rejectionMessage = feedback(for: reason)
        }
    }

    private func handleUndo() {
        guard !isEditingLocked else { return }
        switch routeBuilder.undo() {
        case .undone:
            rejectionMessage = nil
        case .atDepot:
            rejectionMessage = "Route is already back at the Depot."
        }
    }

    private func handleConfirm() {
        guard let job, let grid else { return }
        switch RouteConfirmer.confirm(
            route: routeBuilder.route,
            job: job,
            grid: grid,
            alreadyConfirmed: isEditingLocked
        ) {
        case .confirmed(let input):
            executionInput = input
            rejectionMessage = nil
        case .rejected(.routeIncomplete):
            rejectionMessage = "Reach the Destination before confirming."
        case .rejected(.alreadyConfirmed):
            rejectionMessage = "Route already confirmed."
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
        PlanningScreen()
    }
}
