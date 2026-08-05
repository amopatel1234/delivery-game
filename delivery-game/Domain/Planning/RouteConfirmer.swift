//
//  RouteConfirmer.swift
//  delivery-game
//

import Foundation

/// Why a confirmation attempt was rejected.
nonisolated enum RouteConfirmationRejection: Equatable, Sendable {
    /// Route endpoint is not the destination.
    case routeIncomplete
    /// Confirmation already produced an execution input for this planning session.
    case alreadyConfirmed
}

/// Result of attempting to lock a planned route for execution.
nonisolated enum RouteConfirmationResult: Equatable, Sendable {
    case confirmed(ExecutionInput)
    case rejected(RouteConfirmationRejection)
}

/// Creates an immutable execution input from a complete planned route.
nonisolated enum RouteConfirmer {
    /// Confirms a route only when it is complete and not already confirmed.
    static func confirm(
        route: Route,
        job: SeededJob,
        grid: DeliveryGrid,
        alreadyConfirmed: Bool
    ) -> RouteConfirmationResult {
        if alreadyConfirmed {
            return .rejected(.alreadyConfirmed)
        }

        let validation = RouteValidator.validate(route: route)
        guard validation.canConfirm else {
            return .rejected(.routeIncomplete)
        }

        let request = PlanningAnalysisRequest(
            route: route,
            grid: grid,
            targetTimeMinutes: job.targetTimeMinutes,
            deadlineMinutes: job.deadlineMinutes,
            economy: job.economy
        )
        let analysis = PlanningAnalyzer.analyze(request)
        let summary = PlanningSummaryInput.from(job: job, analysis: analysis)

        let input = ExecutionInput(
            jobID: job.id,
            jobDisplayName: job.displayName,
            route: route,
            grid: grid,
            analysis: analysis,
            summary: summary
        )
        return .confirmed(input)
    }
}
