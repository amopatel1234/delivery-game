//
//  CardResolverTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct CardResolverTests {

    @Test func clearRoadAppliesBaseTravelOnly() {
        guard case .resolved(let outcome) = CardResolver.resolve(cardType: .clearRoad) else {
            Issue.record("Expected clear road to resolve")
            return
        }

        #expect(outcome.baseTravelMinutes == 1)
        #expect(outcome.delayMinutesApplied == 0)
        #expect(outcome.totalMinutesAdded == 1)
        #expect(outcome.didDelay == false)
        #expect(outcome.didDamage == false)
    }

    @Test func lightTrafficAppliesFixedDelayWithoutDamage() {
        guard case .resolved(let outcome) = CardResolver.resolve(cardType: .lightTraffic) else {
            Issue.record("Expected light traffic to resolve")
            return
        }

        #expect(outcome.baseTravelMinutes == 1)
        #expect(outcome.delayMinutesApplied == 1)
        #expect(outcome.totalMinutesAdded == 2)
        #expect(outcome.didDelay == true)
        #expect(outcome.didDamage == false)
    }

    @Test func roadworksAppliesFixedDelayWithoutDamage() {
        guard case .resolved(let outcome) = CardResolver.resolve(cardType: .roadworks) else {
            Issue.record("Expected roadworks to resolve")
            return
        }

        #expect(outcome.baseTravelMinutes == 1)
        #expect(outcome.delayMinutesApplied == 2)
        #expect(outcome.totalMinutesAdded == 3)
        #expect(outcome.didDelay == true)
        #expect(outcome.didDamage == false)
    }

    @Test func fastLaneConsumesZeroTravelTime() {
        guard case .resolved(let outcome) = CardResolver.resolve(cardType: .fastLane) else {
            Issue.record("Expected fast lane to resolve")
            return
        }

        #expect(outcome.baseTravelMinutes == 0)
        #expect(outcome.delayMinutesApplied == 0)
        #expect(outcome.totalMinutesAdded == 0)
        #expect(outcome.didDelay == false)
        #expect(outcome.didDamage == false)
    }

    @Test func heavyTrafficRequiresInjectedHazardDecision() {
        guard case .rejected(let reason) = CardResolver.resolve(cardType: .heavyTraffic) else {
            Issue.record("Expected missing hazard rejection")
            return
        }
        #expect(reason == .missingHeavyTrafficHazard)
    }

    @Test func heavyTrafficWithoutDelayAppliesBaseTravelOnly() {
        guard case .resolved(let outcome) = CardResolver.resolve(
            cardType: .heavyTraffic,
            heavyTrafficHazard: .noHazard
        ) else {
            Issue.record("Expected heavy traffic to resolve")
            return
        }

        #expect(outcome.baseTravelMinutes == 1)
        #expect(outcome.delayMinutesApplied == 0)
        #expect(outcome.didDelay == false)
        #expect(outcome.didDamage == false)
    }

    @Test func heavyTrafficDelayAppliesWithoutDamageWhenNotDamaged() {
        guard case .resolved(let outcome) = CardResolver.resolve(
            cardType: .heavyTraffic,
            heavyTrafficHazard: .delayedOnly
        ) else {
            Issue.record("Expected heavy traffic to resolve")
            return
        }

        #expect(outcome.baseTravelMinutes == 1)
        #expect(outcome.delayMinutesApplied == 2)
        #expect(outcome.totalMinutesAdded == 3)
        #expect(outcome.didDelay == true)
        #expect(outcome.didDamage == false)
    }

    @Test func heavyTrafficDamageOnlyWhenDelayed() {
        guard case .resolved(let delayedDamaged) = CardResolver.resolve(
            cardType: .heavyTraffic,
            heavyTrafficHazard: .delayedAndDamaged
        ) else {
            Issue.record("Expected delayed+damaged resolution")
            return
        }
        #expect(delayedDamaged.didDelay == true)
        #expect(delayedDamaged.didDamage == true)

        // Damage flag is ignored when delay did not occur.
        guard case .resolved(let noDelay) = CardResolver.resolve(
            cardType: .heavyTraffic,
            heavyTrafficHazard: HeavyTrafficHazardOutcome(delayed: false, damaged: true)
        ) else {
            Issue.record("Expected no-delay resolution")
            return
        }
        #expect(noDelay.didDelay == false)
        #expect(noDelay.didDamage == false)
        #expect(noDelay.delayMinutesApplied == 0)
    }

    @Test func nonHeavyTrafficCardsNeverDamage() {
        for type: CardType in [.clearRoad, .lightTraffic, .roadworks, .fastLane] {
            guard case .resolved(let outcome) = CardResolver.resolve(cardType: type) else {
                Issue.record("Expected \(type) to resolve")
                return
            }
            #expect(outcome.didDamage == false)
        }
    }
}
