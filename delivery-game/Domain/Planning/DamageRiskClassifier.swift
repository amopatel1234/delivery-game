//
//  DamageRiskClassifier.swift
//  delivery-game
//

import Foundation

/// Canonical damage risk band used by planning summaries.
nonisolated enum DamageRiskLevel: String, Equatable, Sendable, CaseIterable {
    case low
    case medium
    case high

    var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }
}

/// Configurable damage risk thresholds expressed in permille.
nonisolated struct DamageRiskThresholds: Equatable, Sendable, Hashable {
    /// Inclusive lower bound for Medium (100 == 10%).
    let mediumMinimumPermille: Int

    /// Inclusive lower bound for High (250 == 25%).
    let highMinimumPermille: Int

    static let mvp = DamageRiskThresholds(
        mediumMinimumPermille: 100,
        highMinimumPermille: 250
    )
}

/// Classifies combined route damage risk using canonical gameplay thresholds.
nonisolated enum DamageRiskClassifier {
    static func classify(
        damageProbabilityPermille: Int,
        thresholds: DamageRiskThresholds = .mvp
    ) -> DamageRiskLevel {
        if damageProbabilityPermille >= thresholds.highMinimumPermille {
            return .high
        }
        if damageProbabilityPermille >= thresholds.mediumMinimumPermille {
            return .medium
        }
        return .low
    }

    static func classify(
        segments: [RouteSegment],
        thresholds: DamageRiskThresholds = .mvp
    ) -> DamageRiskLevel {
        let damageProbabilityPermille = IndependentProbability.combinedPermille(
            segments.map(\.rule.overallDamageProbabilityPermille)
        )
        return classify(
            damageProbabilityPermille: damageProbabilityPermille,
            thresholds: thresholds
        )
    }

    static func classify(
        analysis: PlanningAnalysisResult,
        thresholds: DamageRiskThresholds = .mvp
    ) -> DamageRiskLevel {
        classify(
            damageProbabilityPermille: analysis.damageProbabilityPermille,
            thresholds: thresholds
        )
    }
}
