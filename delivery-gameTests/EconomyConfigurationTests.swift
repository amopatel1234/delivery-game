//
//  EconomyConfigurationTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct EconomyConfigurationTests {

    @Test func mvpStoresCanonicalSharedValues() {
        let economy = EconomyConfiguration.mvp

        #expect(economy.baseReward == 100)
        #expect(economy.earlyBonusPerMinute == 5)
        #expect(economy.latenessPenaltyPerMinute == 20)
        #expect(economy.damagePenaltyPerEvent == 20)
        #expect(economy.minimumReward == 0)
    }

    @Test func customConfigurationCanBeInjected() {
        let custom = EconomyConfiguration(
            baseReward: 250,
            earlyBonusPerMinute: 10,
            latenessPenaltyPerMinute: 15,
            damagePenaltyPerEvent: 25,
            minimumReward: 0
        )

        #expect(custom.baseReward == 250)
        #expect(custom.earlyBonusPerMinute == 10)
        #expect(custom.latenessPenaltyPerMinute == 15)
        #expect(custom.damagePenaltyPerEvent == 25)
        #expect(custom != EconomyConfiguration.mvp)
    }

    @Test func clampRewardEnforcesCanonicalMinimum() {
        let economy = EconomyConfiguration.mvp

        #expect(economy.clampReward(40) == 40)
        #expect(economy.clampReward(0) == 0)
        #expect(economy.clampReward(-15) == 0)
    }

    @Test func customMinimumRewardIsHonouredByClamp() {
        let economy = EconomyConfiguration(
            baseReward: 100,
            earlyBonusPerMinute: 5,
            latenessPenaltyPerMinute: 20,
            damagePenaltyPerEvent: 20,
            minimumReward: 10
        )

        #expect(economy.clampReward(25) == 25)
        #expect(economy.clampReward(10) == 10)
        #expect(economy.clampReward(3) == 10)
        #expect(economy.clampReward(-100) == 10)
    }
}
