//
//  PresentationMotion.swift
//  delivery-game
//

import Foundation

/// Centrally configurable presentation timing. Independent of domain resolution.
nonisolated enum PresentationMotion {
    /// Visual cadence between revealed execution cards (nanoseconds).
    static let executionStepNanoseconds: UInt64 = 450_000_000

    /// Short selection / undo highlight (seconds).
    static let routeChromeSeconds: Double = 0.18

    /// Consequence chip emphasis (seconds).
    static let consequenceEmphasisSeconds: Double = 0.28

    /// Duration used when Reduce Motion is preferred (E6-S03).
    static let reducedMotionSeconds: Double = 0.01

    static func routeChromeDuration(reduceMotion: Bool) -> Double {
        reduceMotion ? reducedMotionSeconds : routeChromeSeconds
    }

    static func consequenceDuration(reduceMotion: Bool) -> Double {
        reduceMotion ? reducedMotionSeconds : consequenceEmphasisSeconds
    }

    static func executionStepNanoseconds(reduceMotion: Bool) -> UInt64 {
        reduceMotion ? 0 : executionStepNanoseconds
    }
}
