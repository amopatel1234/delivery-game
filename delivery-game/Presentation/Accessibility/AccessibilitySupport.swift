//
//  AccessibilitySupport.swift
//  delivery-game
//

import Foundation

/// sRGB colour sample used for contrast checks (presentation-neutral).
nonisolated struct AccessibilityRGB: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    /// WCAG relative luminance.
    var relativeLuminance: Double {
        func channel(_ value: Double) -> Double {
            let c = max(0, min(value, 1))
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let r = channel(red)
        let g = channel(green)
        let b = channel(blue)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Contrast ratio between two colours (1…21).
    static func contrastRatio(_ a: AccessibilityRGB, _ b: AccessibilityRGB) -> Double {
        let l1 = a.relativeLuminance
        let l2 = b.relativeLuminance
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

/// Palette samples matching `GridPalette` for automated contrast validation.
nonisolated enum AccessibilityPaletteSamples {
    static let canvas = AccessibilityRGB(red: 0.10, green: 0.14, blue: 0.18)
    static let panel = AccessibilityRGB(red: 0.14, green: 0.19, blue: 0.24)
    static let ink = AccessibilityRGB(red: 0.93, green: 0.95, blue: 0.97)
    static let mutedInk = AccessibilityRGB(red: 0.70, green: 0.76, blue: 0.82)
    static let accent = AccessibilityRGB(red: 0.98, green: 0.62, blue: 0.22)
    static let depot = AccessibilityRGB(red: 0.20, green: 0.70, blue: 0.55)
    static let destination = AccessibilityRGB(red: 0.95, green: 0.35, blue: 0.38)

    /// WCAG AA normal text minimum.
    static let aaNormalTextMinimum = 4.5
    /// WCAG AA large / UI-component minimum.
    static let aaLargeTextMinimum = 3.0

    static var primaryTextOnCanvas: Double {
        AccessibilityRGB.contrastRatio(ink, canvas)
    }

    static var primaryTextOnPanel: Double {
        AccessibilityRGB.contrastRatio(ink, panel)
    }

    static var mutedTextOnCanvas: Double {
        AccessibilityRGB.contrastRatio(mutedInk, canvas)
    }

    static var accentOnCanvas: Double {
        AccessibilityRGB.contrastRatio(accent, canvas)
    }
}

/// VoiceOver labels and hints shared by interactive controls.
nonisolated enum AccessibilityCopy {
    static let startGameLabel = "Start Game"
    static let startGameHint = "Begins the seeded job sequence. Shows How to Play on first launch."

    static let undoLabel = "Undo last route step"
    static let undoHint = "Removes the most recent card from the route."
    static let undoDisabledHint = "No route steps to undo."

    static let confirmLabel = "Confirm route"
    static let confirmHint = "Locks the route and starts execution."
    static let confirmDisabledHint = "Reach the Destination before confirming."

    static let continueLabel = "Continue"
    static let continueHint = "Advances to the next job or replay selection."

    static let skipOnboardingLabel = "Skip onboarding"
    static let skipOnboardingHint = "Dismisses How to Play and starts Job 1."

    static func cellHint(isInteractive: Bool, isLocked: Bool) -> String? {
        if isLocked {
            return "Route is locked during execution."
        }
        if isInteractive {
            return "Double tap to add this card to the route if it is beside the route end."
        }
        return nil
    }

    static func announceRouteRejection(_ message: String) -> String {
        "Invalid move. \(message)"
    }

    static func announceRouteStepCount(_ steps: Int) -> String {
        "Route updated. \(steps) step\(steps == 1 ? "" : "s") after Depot."
    }

    static func announceExecutionConsequence(_ kind: ExecutionConsequenceKind) -> String {
        switch kind {
        case .movement:
            "Card resolved with normal movement."
        case .delay:
            "Card resolved with a delay."
        case .damage:
            "Card resolved with a damage event."
        }
    }

    static func announceOutcome(completed: Bool, reward: Int) -> String {
        if completed {
            return "Delivery complete. Reward \(reward) coins."
        }
        return "Delivery failed. Reward \(reward) coins."
    }
}
