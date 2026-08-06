//
//  OnboardingStore.swift
//  delivery-game
//

import Foundation

/// Persistence for lightweight onboarding-completion state.
nonisolated protocol OnboardingPersisting: AnyObject, Sendable {
    var hasCompletedOnboarding: Bool { get set }
}

/// UserDefaults-backed onboarding completion flag.
nonisolated final class UserDefaultsOnboardingStore: OnboardingPersisting, @unchecked Sendable {
    static let defaultKey = "couriersgambit.onboarding.completed"

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = UserDefaultsOnboardingStore.defaultKey) {
        self.defaults = defaults
        self.key = key
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: key) }
        set { defaults.set(newValue, forKey: key) }
    }
}

/// In-memory store for unit tests and previews.
nonisolated final class InMemoryOnboardingStore: OnboardingPersisting, @unchecked Sendable {
    var hasCompletedOnboarding: Bool

    init(hasCompletedOnboarding: Bool = false) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

/// Pure helpers over onboarding completion state.
nonisolated enum OnboardingCoordinator {
    /// Whether Start Game should show onboarding first.
    static func shouldPresentOnboarding(store: OnboardingPersisting) -> Bool {
        !store.hasCompletedOnboarding
    }

    /// Marks onboarding finished (completed or skipped).
    static func markCompleted(store: OnboardingPersisting) {
        store.hasCompletedOnboarding = true
    }

    /// Clears completion so first-run guidance appears again (DEBUG / tests).
    static func reset(store: OnboardingPersisting) {
        store.hasCompletedOnboarding = false
    }
}
