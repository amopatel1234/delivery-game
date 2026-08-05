//
//  IndependentProbability.swift
//  delivery-game
//

import Foundation

/// Combines independent event probabilities using `1 - product(1 - p)`.
nonisolated enum IndependentProbability {
    /// Combines independent event probabilities expressed in permille (0...1000).
    static func combinedPermille(_ eventPermilles: [Int]) -> Int {
        guard let first = eventPermilles.first else { return 0 }

        var survivalProduct = 1000 - first
        for permille in eventPermilles.dropFirst() {
            survivalProduct *= 1000 - permille
        }

        var divisor = 1
        for _ in 1 ..< eventPermilles.count {
            divisor *= 1000
        }

        return 1000 - survivalProduct / divisor
    }
}
