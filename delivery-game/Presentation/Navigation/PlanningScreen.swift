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
    @State private var lockedSummary: PlanningSummaryInput?
    @State private var executionPresentation: ExecutionPresentationState?
    @State private var sealedEventLog: ExecutionEventLog?
    @State private var playbackTask: Task<Void, Never>?
    @State private var loadErrorMessage: String?
    @State private var rejectionMessage: String?

    init(jobID: SeededJobID = SeededJobCatalogue.defaultJobID) {
        self.jobID = jobID
    }

    private var isEditingLocked: Bool {
        executionInput != nil
    }

    /// Recap appears once playback reaches the completed phase.
    private var completedRecap: ExecutionRecap? {
        guard
            executionPresentation?.phase == .completed,
            let executionInput,
            let sealedEventLog
        else {
            return nil
        }
        return ExecutionRecap.from(input: executionInput, eventLog: sealedEventLog)
    }

    private var validation: RouteValidationResult {
        RouteValidator.validate(route: routeBuilder.route)
    }

    private var summary: PlanningSummaryInput {
        if let lockedSummary {
            return lockedSummary
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
                            playerCoordinate: executionPresentation?.playerCoordinate,
                            activeCoordinate: executionPresentation?.activeCoordinate,
                            onSelect: isEditingLocked
                                ? nil
                                : { coordinate in
                                    handleSelection(coordinate)
                                }
                        )
                        .aspectRatio(1, contentMode: .fit)
                        .allowsHitTesting(!isEditingLocked)

                        PlanningSummaryView(summary: summary)

                        if let executionInput {
                            ExecutionHandoffView(
                                input: executionInput,
                                presentation: executionPresentation
                            )
                        }

                        if let recap = completedRecap {
                            ExecutionRecapView(recap: recap)
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
        .onDisappear {
            playbackTask?.cancel()
            playbackTask = nil
        }
    }

    private var routeStatusText: String {
        if let executionPresentation {
            return executionPresentation.statusMessage
        }
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
        if executionPresentation?.phase == .completed {
            return GridPalette.depot
        }
        if isEditingLocked {
            return GridPalette.accent
        }
        if rejectionMessage != nil {
            return GridPalette.destination
        }
        return GridPalette.mutedInk
    }

    private func loadJob() {
        playbackTask?.cancel()
        playbackTask = nil
        do {
            let loadedJob = try SeededJobCatalogue.load(id: jobID)
            job = loadedJob
            grid = try DeliveryGrid(board: loadedJob.board)
            routeBuilder = RouteBuilder()
            executionInput = nil
            lockedSummary = nil
            executionPresentation = nil
            sealedEventLog = nil
            rejectionMessage = nil
            loadErrorMessage = nil
        } catch {
            job = nil
            grid = nil
            executionInput = nil
            lockedSummary = nil
            executionPresentation = nil
            sealedEventLog = nil
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
            lockedSummary = summary
            rejectionMessage = nil
            beginExecutionPlayback(input: input, seed: job.seed)
        case .rejected(.routeIncomplete):
            rejectionMessage = "Reach the Destination before confirming."
        case .rejected(.alreadyConfirmed):
            rejectionMessage = "Route already confirmed."
        }
    }

    private func beginExecutionPlayback(input: ExecutionInput, seed: UInt64) {
        playbackTask?.cancel()

        let prepared = ExecutionRunPreparer.prepare(input: input, seed: seed)
        sealedEventLog = prepared.eventLog
        executionPresentation = .ready(
            input: input,
            eventCount: prepared.eventLog.events.count
        )

        let events = prepared.eventLog.events
        playbackTask = Task { @MainActor in
            guard !events.isEmpty else { return }
            for revealed in 1 ... events.count {
                if Task.isCancelled { return }
                try? await Task.sleep(
                    nanoseconds: ExecutionRunPreparer.defaultStepDelayNanoseconds
                )
                if Task.isCancelled { return }
                executionPresentation = .snapshot(
                    input: input,
                    events: events,
                    revealedEventCount: revealed
                )
            }
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
