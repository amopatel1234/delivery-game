//
//  OnboardingContent.swift
//  delivery-game
//

import Foundation

/// One page in the first-run onboarding flow.
nonisolated struct OnboardingPage: Equatable, Sendable, Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let symbolName: String
}

/// Authored first-run guidance pages (presentation-neutral).
nonisolated enum OnboardingContent {
    /// Ordered pages shown to first-time players.
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: "objective",
            title: "Plan the route",
            body: "Choose a path from the Depot to the Destination. Better routes earn more coins — watch the planning summary as you build.",
            symbolName: "map.fill"
        ),
        OnboardingPage(
            id: "construction",
            title: "Build card by card",
            body: "Tap cards beside the route end. Moves must be orthogonal — no diagonals. Use Undo to step back, then Confirm Route when you reach the Destination.",
            symbolName: "hand.tap.fill"
        ),
        OnboardingPage(
            id: "timing",
            title: "Target Time and Deadline",
            body: "Beat the Target Time for an early bonus. Arrive after Target Time but before the Deadline for a late penalty. Miss the Deadline and the run fails with zero reward.",
            symbolName: "clock.fill"
        ),
        OnboardingPage(
            id: "risk",
            title: "Delay and damage",
            body: "Some cards may add delay or cause damage when resolved. Delay and damage are separate — both can reduce your payout on a completed run.",
            symbolName: "exclamationmark.triangle.fill"
        ),
        OnboardingPage(
            id: "reward",
            title: "Maximum reward",
            body: "The planning summary shows the best possible payout for a perfect arrival with no damage. Actual reward depends on how execution resolves.",
            symbolName: "dollarsign.circle.fill"
        ),
    ]

    static var pageCount: Int { pages.count }
}
