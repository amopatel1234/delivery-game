//
//  PlanningSummaryInput.swift
//  delivery-game
//

import Foundation

/// One planning metric row for presentation.
nonisolated struct PlanningMetric: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let value: String
    let isAvailable: Bool

    var accessibilityLabel: String {
        "\(title): \(value)"
    }
}

/// Presentation-neutral planning summary consumed by the planning screen.
nonisolated struct PlanningSummaryInput: Equatable, Sendable {
    let targetTimeMinutes: Int
    let deadlineMinutes: Int
    let estimatedArrivalMinutes: Int?
    let delayExposure: String?
    let damageRisk: String?
    let maximumReward: Int?

    var metrics: [PlanningMetric] {
        [
            PlanningMetric(
                id: "estimated_arrival",
                title: "Estimated arrival",
                value: formattedEstimatedArrival(estimatedArrivalMinutes),
                isAvailable: estimatedArrivalMinutes != nil
            ),
            PlanningMetric(
                id: "target_time",
                title: "Target time",
                value: "\(targetTimeMinutes) min",
                isAvailable: true
            ),
            PlanningMetric(
                id: "deadline",
                title: "Deadline",
                value: "\(deadlineMinutes) min",
                isAvailable: true
            ),
            PlanningMetric(
                id: "delay_exposure",
                title: "Delay exposure",
                value: delayExposure ?? Self.unavailableLabel,
                isAvailable: delayExposure != nil
            ),
            PlanningMetric(
                id: "damage_risk",
                title: "Damage risk",
                value: damageRisk ?? Self.unavailableLabel,
                isAvailable: damageRisk != nil
            ),
            PlanningMetric(
                id: "maximum_reward",
                title: "Maximum reward",
                value: formattedReward(maximumReward),
                isAvailable: maximumReward != nil
            ),
        ]
    }

    private static let unavailableLabel = "Unavailable"

    /// Builds the summary surface from job data before analysis is available.
    static func from(job: SeededJob) -> PlanningSummaryInput {
        PlanningSummaryInput(
            targetTimeMinutes: job.targetTimeMinutes,
            deadlineMinutes: job.deadlineMinutes,
            estimatedArrivalMinutes: nil,
            delayExposure: nil,
            damageRisk: nil,
            maximumReward: nil
        )
    }

    /// Builds a live summary from the current route analysis.
    static func from(
        job: SeededJob,
        route: Route,
        grid: DeliveryGrid
    ) -> PlanningSummaryInput {
        let request = PlanningAnalysisRequest(
            route: route,
            grid: grid,
            targetTimeMinutes: job.targetTimeMinutes,
            deadlineMinutes: job.deadlineMinutes,
            economy: job.economy
        )
        return from(job: job, analysis: PlanningAnalyzer.analyze(request))
    }

    /// Maps a completed analysis into presentation values.
    static func from(
        job: SeededJob,
        analysis: PlanningAnalysisResult
    ) -> PlanningSummaryInput {
        PlanningSummaryInput(
            targetTimeMinutes: job.targetTimeMinutes,
            deadlineMinutes: job.deadlineMinutes,
            estimatedArrivalMinutes: analysis.estimatedArrivalMinutes,
            delayExposure: DelayExposureClassifier.classify(analysis: analysis).displayName,
            damageRisk: DamageRiskClassifier.classify(analysis: analysis).displayName,
            maximumReward: MaximumRewardEstimator.estimate(analysis: analysis)
        )
    }

    private func formattedEstimatedArrival(_ minutes: Int?) -> String {
        guard let minutes else { return Self.unavailableLabel }
        return "~\(minutes) min"
    }

    private func formattedReward(_ reward: Int?) -> String {
        guard let reward else { return Self.unavailableLabel }
        return "\(reward) coins"
    }
}
