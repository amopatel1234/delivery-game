//
//  OnboardingCoordinatorTests.swift
//  delivery-gameTests
//

import Foundation
import Testing
@testable import delivery_game

struct OnboardingCoordinatorTests {

    @Test func cleanStatePresentsOnboarding() {
        let store = InMemoryOnboardingStore(hasCompletedOnboarding: false)
        #expect(OnboardingCoordinator.shouldPresentOnboarding(store: store))
    }

    @Test func completedStateSkipsOnboarding() {
        let store = InMemoryOnboardingStore(hasCompletedOnboarding: true)
        #expect(OnboardingCoordinator.shouldPresentOnboarding(store: store) == false)
    }

    @Test func markCompletedPersistsAcrossReads() {
        let store = InMemoryOnboardingStore(hasCompletedOnboarding: false)
        OnboardingCoordinator.markCompleted(store: store)

        #expect(store.hasCompletedOnboarding)
        #expect(OnboardingCoordinator.shouldPresentOnboarding(store: store) == false)
    }

    @Test func resetClearsCompletionForDevelopment() {
        let store = InMemoryOnboardingStore(hasCompletedOnboarding: true)
        OnboardingCoordinator.reset(store: store)

        #expect(store.hasCompletedOnboarding == false)
        #expect(OnboardingCoordinator.shouldPresentOnboarding(store: store))
    }

    @Test func userDefaultsStorePersistsCompletion() {
        let suiteName = "OnboardingCoordinatorTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Expected ephemeral UserDefaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsOnboardingStore(defaults: defaults)
        #expect(OnboardingCoordinator.shouldPresentOnboarding(store: store))

        OnboardingCoordinator.markCompleted(store: store)
        let reloaded = UserDefaultsOnboardingStore(defaults: defaults)
        #expect(reloaded.hasCompletedOnboarding)
        #expect(OnboardingCoordinator.shouldPresentOnboarding(store: reloaded) == false)

        OnboardingCoordinator.reset(store: reloaded)
        #expect(OnboardingCoordinator.shouldPresentOnboarding(store: reloaded))
    }

    @Test func authoredPagesCoverCoreLoopTopics() {
        let ids = OnboardingContent.pages.map(\.id)
        #expect(ids == ["objective", "construction", "timing", "risk", "reward"])
        #expect(OnboardingContent.pageCount == 5)
        #expect(OnboardingContent.pages.allSatisfy { !$0.title.isEmpty && !$0.body.isEmpty })
    }

    @Test func accessibilityIdentifiersAreStable() {
        #expect(GridAccessibilityID.onboarding == "onboarding")
        #expect(GridAccessibilityID.onboardingSkipButton == "onboarding-skip")
        #expect(GridAccessibilityID.onboardingPrimaryButton == "onboarding-primary")
        #expect(GridAccessibilityID.resetOnboardingButton == "main-menu-reset-onboarding")
    }
}
