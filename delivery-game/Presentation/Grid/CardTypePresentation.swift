//
//  CardTypePresentation.swift
//  delivery-game
//

import Foundation

/// Presentation metadata for a card type.
/// Kept free of SwiftUI so views and tests can share the same mapping.
nonisolated struct CardTypePresentation: Equatable, Sendable {
    let symbolName: String
    let title: String
    /// Compact non-colour code shown on grid cells.
    let shortCode: String
    let accessibilityLabel: String

    static func forType(_ type: CardType) -> CardTypePresentation {
        switch type {
        case .clearRoad:
            CardTypePresentation(
                symbolName: "road.lanes",
                title: "Clear Road",
                shortCode: "CR",
                accessibilityLabel: "Clear Road"
            )
        case .lightTraffic:
            CardTypePresentation(
                symbolName: "car.fill",
                title: "Light Traffic",
                shortCode: "LT",
                accessibilityLabel: "Light Traffic"
            )
        case .heavyTraffic:
            CardTypePresentation(
                symbolName: "truck.box.fill",
                title: "Heavy Traffic",
                shortCode: "HT",
                accessibilityLabel: "Heavy Traffic"
            )
        case .roadworks:
            CardTypePresentation(
                symbolName: "cone.fill",
                title: "Roadworks",
                shortCode: "RW",
                accessibilityLabel: "Roadworks"
            )
        case .fastLane:
            CardTypePresentation(
                symbolName: "bolt.fill",
                title: "Fast Lane",
                shortCode: "FL",
                accessibilityLabel: "Fast Lane"
            )
        }
    }
}

/// Stable accessibility identifiers for grid presentation.
nonisolated enum GridAccessibilityID {
    static let board = "grid-board"
    static let mainMenu = "main-menu"
    static let startGameButton = "main-menu-start-game"
    static let resetOnboardingButton = "main-menu-reset-onboarding"
    static let routeStatus = "route-status"
    static let onboarding = "onboarding"
    static let onboardingTitle = "onboarding-title"
    static let onboardingBody = "onboarding-body"
    static let onboardingPageIndicator = "onboarding-page-indicator"
    static let onboardingSkipButton = "onboarding-skip"
    static let onboardingPrimaryButton = "onboarding-primary"
    static let undoButton = "route-undo-button"
    static let routeValidationStatus = "route-validation-status"
    static let planningSummary = "planning-summary"
    static let confirmRouteButton = "route-confirm-button"
    static let executionHandoff = "execution-handoff"
    static let executionProgressPanel = "execution-progress-panel"
    static let executionProgress = "execution-progress"
    static let executionElapsed = "execution-elapsed"
    static let executionDamage = "execution-damage"
    static let executionStatus = "execution-status"
    static let executionConsequence = "execution-consequence"
    static let executionRecap = "execution-recap"
    static let executionRecapSummary = "execution-recap-summary"
    static let executionRecapList = "execution-recap-list"
    static let resultsScreen = "results-screen"
    static let resultsHeading = "results-heading"
    static let resultsReward = "results-reward"
    static let resultsTiming = "results-timing"
    static let resultsBreakdown = "results-breakdown"
    static let resultsContinueButton = "results-continue-button"
    static let jobSelection = "job-selection"

    static func executionRecapEntry(_ index: Int) -> String {
        "execution-recap-entry-\(index)"
    }

    static func resultsTimingRow(_ id: String) -> String {
        "results-timing-\(id)"
    }

    static func resultsBreakdownRow(_ id: String) -> String {
        "results-breakdown-\(id)"
    }

    static func jobSelectionOption(_ jobID: SeededJobID) -> String {
        "job-selection-\(jobID.rawValue)"
    }

    static func planningMetric(_ id: String) -> String {
        "planning-metric-\(id)"
    }

    static func cell(row: Int, column: Int) -> String {
        "grid-cell-r\(row)-c\(column)"
    }

    static func cell(_ coordinate: GridCoordinate) -> String {
        cell(row: coordinate.row, column: coordinate.column)
    }
}
