//
//  PlanningAnalysisResult.swift
//  delivery-game
//

import Foundation

/// One entered card on the route after the depot.
nonisolated struct RouteSegment: Equatable, Sendable {
    let coordinate: GridCoordinate
    let cardType: CardType
    let rule: CardRuleDefinition
}

/// Inputs required by the maximum-reward estimator in a later story.
nonisolated struct MaximumRewardEstimationInput: Equatable, Sendable {
    let deterministicArrivalMinutes: Int
    let targetTimeMinutes: Int
    let deadlineMinutes: Int
    let economy: EconomyConfiguration
}

/// Presentation-independent planning analysis for a route and job.
nonisolated struct PlanningAnalysisResult: Equatable, Sendable {
    /// Ordered entered cards after the depot.
    let enteredSegments: [RouteSegment]

    /// Deterministic travel time: base movement plus guaranteed delays only.
    let estimatedArrivalMinutes: Int

    /// Combined delay probability in permille (750 == 75%).
    let delayProbabilityPermille: Int

    /// Combined damage probability in permille (75 == 7.5%).
    let damageProbabilityPermille: Int

    let maximumRewardEstimationInput: MaximumRewardEstimationInput
}
