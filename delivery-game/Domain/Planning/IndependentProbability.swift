//
//  IndependentProbability.swift
//  delivery-game
//

import Foundation

/// Combines independent event probabilities using `1 - product(1 - p)`.
nonisolated enum IndependentProbability {
    /// Combines independent event probabilities expressed in permille (0...1000).
    ///
    /// Uses an incremental form so intermediate products stay within 0...1000 and
    /// cannot overflow on long routes (e.g. many zero-probability Clear Road cards).
    static func combinedPermille(_ eventPermilles: [Int]) -> Int {
        var combined = 0
        for raw in eventPermilles {
            let permille = min(max(raw, 0), 1000)
            // 1 - (1 - c)(1 - p)  ⇒  c + p - c·p / 1000  (integer permille arithmetic)
            combined = combined + permille - (combined * permille) / 1000
        }
        return combined
    }
}
