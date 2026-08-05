//
//  PlanningAnalyzer.swift
//  delivery-game
//

import Foundation

/// Immutable inputs for route planning analysis.
nonisolated struct PlanningAnalysisRequest: Equatable, Sendable {
    let route: Route
    let grid: DeliveryGrid
    let targetTimeMinutes: Int
    let deadlineMinutes: Int
    let economy: EconomyConfiguration

    init(route: Route, job: SeededJob) throws {
        self.route = route
        self.grid = try DeliveryGrid(board: job.board)
        self.targetTimeMinutes = job.targetTimeMinutes
        self.deadlineMinutes = job.deadlineMinutes
        self.economy = job.economy
    }

    init(
        route: Route,
        grid: DeliveryGrid,
        targetTimeMinutes: Int,
        deadlineMinutes: Int,
        economy: EconomyConfiguration
    ) {
        self.route = route
        self.grid = grid
        self.targetTimeMinutes = targetTimeMinutes
        self.deadlineMinutes = deadlineMinutes
        self.economy = economy
    }
}

/// Deterministic planning analysis with no randomness.
nonisolated enum PlanningAnalyzer {
    static func analyze(_ request: PlanningAnalysisRequest) -> PlanningAnalysisResult {
        let segments = enteredSegments(route: request.route, grid: request.grid)
        let estimatedArrivalMinutes = segments.reduce(0) { partial, segment in
            partial + deterministicTravelMinutes(for: segment.rule)
        }

        let delayProbabilityPermille = IndependentProbability.combinedPermille(
            segments.map(delayProbabilityPermille(for:))
        )
        let damageProbabilityPermille = IndependentProbability.combinedPermille(
            segments.map(\.rule.overallDamageProbabilityPermille)
        )

        return PlanningAnalysisResult(
            enteredSegments: segments,
            estimatedArrivalMinutes: estimatedArrivalMinutes,
            delayProbabilityPermille: delayProbabilityPermille,
            damageProbabilityPermille: damageProbabilityPermille,
            maximumRewardEstimationInput: MaximumRewardEstimationInput(
                deterministicArrivalMinutes: estimatedArrivalMinutes,
                targetTimeMinutes: request.targetTimeMinutes,
                deadlineMinutes: request.deadlineMinutes,
                economy: request.economy
            )
        )
    }

    static func enteredSegments(
        route: Route,
        grid: DeliveryGrid
    ) -> [RouteSegment] {
        route.coordinates.dropFirst().map { coordinate in
            let cardType = grid.cardType(at: coordinate)
            return RouteSegment(
                coordinate: coordinate,
                cardType: cardType,
                rule: CardRules.definition(for: cardType)
            )
        }
    }

    static func deterministicTravelMinutes(for rule: CardRuleDefinition) -> Int {
        var minutes = rule.baseTravelTimeMinutes
        if rule.delayProbabilityPercent == 100 {
            minutes += rule.delayMinutes
        }
        return minutes
    }

    static func delayProbabilityPermille(for segment: RouteSegment) -> Int {
        segment.rule.delayProbabilityPercent * 10
    }
}
