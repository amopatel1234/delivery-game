//
//  HazardResolver.swift
//  delivery-game
//

import Foundation

/// Outcome of resolving a Heavy Traffic hazard with sequential RNG rolls.
nonisolated struct HazardResolutionResult: Equatable, Sendable {
    let outcome: HeavyTrafficHazardOutcome
    /// Inclusive 1...100 roll used for the delay chance check.
    let delayRoll: Int
    /// Inclusive 1...100 roll used for damage only when delay succeeds; otherwise `nil`.
    let damageRoll: Int?
    /// Number of RNG values consumed (1 when delay fails; 2 when delay succeeds).
    let rollsConsumed: Int
}

/// Resolves Heavy Traffic delay/damage chances against an injected RNG.
///
/// Rolls are inclusive integers in `1...100`. A check with chance `c` succeeds when
/// `roll <= c` (so chance `0` never succeeds and chance `100` always succeeds).
nonisolated enum HazardResolver {
    /// Returns whether a roll in `1...100` succeeds against `chancePercent` (0...100).
    static func succeeds(roll: Int, chancePercent: Int) -> Bool {
        precondition((1...100).contains(roll), "roll must be in 1...100")
        precondition((0...100).contains(chancePercent), "chancePercent must be in 0...100")
        return roll <= chancePercent
    }

    /// Resolves Heavy Traffic using sequential rolls from `rng`.
    ///
    /// Always consumes one roll for delay. Consumes a second roll for damage only when
    /// the delay check succeeds — a failed delay never draws a damage roll.
    static func resolveHeavyTraffic(
        rule: CardRuleDefinition = CardRules.heavyTraffic,
        rng: inout some RandomNumberGenerating
    ) -> HazardResolutionResult {
        let delayRoll = rng.rollPercent()
        let delayed = succeeds(roll: delayRoll, chancePercent: rule.delayProbabilityPercent)

        guard delayed else {
            return HazardResolutionResult(
                outcome: HeavyTrafficHazardOutcome(delayed: false, damaged: false),
                delayRoll: delayRoll,
                damageRoll: nil,
                rollsConsumed: 1
            )
        }

        let damageRoll = rng.rollPercent()
        let damaged = succeeds(
            roll: damageRoll,
            chancePercent: rule.conditionalDamageProbabilityPercent
        )
        return HazardResolutionResult(
            outcome: HeavyTrafficHazardOutcome(delayed: true, damaged: damaged),
            delayRoll: delayRoll,
            damageRoll: damageRoll,
            rollsConsumed: 2
        )
    }
}
