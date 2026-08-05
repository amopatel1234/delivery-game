//
//  DelayExposureClassifier.swift
//  delivery-game
//

import Foundation

/// Canonical delay exposure band used by planning summaries.
nonisolated enum DelayExposureLevel: String, Equatable, Sendable, CaseIterable {
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

/// Configurable delay exposure thresholds expressed in permille.
nonisolated struct DelayExposureThresholds: Equatable, Sendable, Hashable {
    /// Inclusive lower bound for Medium (250 == 25%).
    let mediumMinimumPermille: Int

    /// Inclusive lower bound for High (500 == 50%).
    let highMinimumPermille: Int

    static let mvp = DelayExposureThresholds(
        mediumMinimumPermille: 250,
        highMinimumPermille: 500
    )
}

/// Classifies combined route delay exposure using canonical gameplay thresholds.
nonisolated enum DelayExposureClassifier {
    static func classify(
        delayProbabilityPermille: Int,
        thresholds: DelayExposureThresholds = .mvp
    ) -> DelayExposureLevel {
        if delayProbabilityPermille >= thresholds.highMinimumPermille {
            return .high
        }
        if delayProbabilityPermille >= thresholds.mediumMinimumPermille {
            return .medium
        }
        return .low
    }

    static func classify(
        segments: [RouteSegment],
        thresholds: DelayExposureThresholds = .mvp
    ) -> DelayExposureLevel {
        let delayProbabilityPermille = IndependentProbability.combinedPermille(
            segments.map(PlanningAnalyzer.delayProbabilityPermille(for:))
        )
        return classify(
            delayProbabilityPermille: delayProbabilityPermille,
            thresholds: thresholds
        )
    }

    static func classify(
        analysis: PlanningAnalysisResult,
        thresholds: DelayExposureThresholds = .mvp
    ) -> DelayExposureLevel {
        classify(
            delayProbabilityPermille: analysis.delayProbabilityPermille,
            thresholds: thresholds
        )
    }
}
