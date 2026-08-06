//
//  ResultsScreenInput.swift
//  delivery-game
//

import Foundation

/// Presentation-neutral payload for the post-run results screen.
nonisolated struct ResultsScreenInput: Equatable, Sendable, Hashable {
    let jobDisplayName: String
    let breakdown: OutcomeBreakdown
    let recap: ExecutionRecap

    /// Builds results content from a finished execution hand-off.
    static func from(result: ExecutionResult) -> ResultsScreenInput {
        ResultsScreenInput(
            jobDisplayName: result.input.jobDisplayName,
            breakdown: OutcomeBreakdownBuilder.build(from: result),
            recap: result.recap
        )
    }
}
