//
//  AccessibilitySupportTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct AccessibilitySupportTests {

    @Test func primaryTextMeetsWCAGAAOnCanvasAndPanel() {
        #expect(AccessibilityPaletteSamples.primaryTextOnCanvas >= AccessibilityPaletteSamples.aaNormalTextMinimum)
        #expect(AccessibilityPaletteSamples.primaryTextOnPanel >= AccessibilityPaletteSamples.aaNormalTextMinimum)
    }

    @Test func mutedTextAndAccentMeetLargeTextMinimumOnCanvas() {
        #expect(AccessibilityPaletteSamples.mutedTextOnCanvas >= AccessibilityPaletteSamples.aaLargeTextMinimum)
        #expect(AccessibilityPaletteSamples.accentOnCanvas >= AccessibilityPaletteSamples.aaLargeTextMinimum)
    }

    @Test func contrastRatioIsSymmetricAndAtLeastOne() {
        let ratio = AccessibilityRGB.contrastRatio(
            AccessibilityPaletteSamples.ink,
            AccessibilityPaletteSamples.canvas
        )
        let reverse = AccessibilityRGB.contrastRatio(
            AccessibilityPaletteSamples.canvas,
            AccessibilityPaletteSamples.ink
        )
        #expect(abs(ratio - reverse) < 0.0001)
        #expect(ratio >= 1)
    }

    @Test func interactiveControlCopyIncludesLabelsAndHints() {
        #expect(!AccessibilityCopy.startGameLabel.isEmpty)
        #expect(!AccessibilityCopy.startGameHint.isEmpty)
        #expect(!AccessibilityCopy.undoHint.isEmpty)
        #expect(!AccessibilityCopy.confirmDisabledHint.isEmpty)
        #expect(!AccessibilityCopy.continueHint.isEmpty)
    }

    @Test func cellHintsDistinguishInteractiveAndLockedStates() {
        #expect(AccessibilityCopy.cellHint(isInteractive: true, isLocked: false) != nil)
        #expect(AccessibilityCopy.cellHint(isInteractive: false, isLocked: true)?.contains("locked") == true)
        #expect(AccessibilityCopy.cellHint(isInteractive: false, isLocked: false) == nil)
    }

    @Test func announcementsCoverRouteExecutionAndOutcome() {
        #expect(AccessibilityCopy.announceRouteRejection("Blocked").contains("Invalid move"))
        #expect(AccessibilityCopy.announceRouteStepCount(1).contains("1 step"))
        #expect(AccessibilityCopy.announceRouteStepCount(2).contains("2 steps"))
        #expect(AccessibilityCopy.announceExecutionConsequence(.damage).contains("damage"))
        #expect(AccessibilityCopy.announceOutcome(completed: true, reward: 110).contains("110"))
        #expect(AccessibilityCopy.announceOutcome(completed: false, reward: 0).contains("failed"))
    }

    @Test func reduceMotionCollapsesExecutionCadence() {
        #expect(PresentationMotion.executionStepNanoseconds(reduceMotion: true) == 0)
        #expect(
            PresentationMotion.executionStepNanoseconds(reduceMotion: false)
                == PresentationMotion.executionStepNanoseconds
        )
        #expect(
            PresentationMotion.routeChromeDuration(reduceMotion: true)
                < PresentationMotion.routeChromeDuration(reduceMotion: false)
        )
    }

    @Test func routeStatusAccessibilityIdentifierIsStable() {
        #expect(GridAccessibilityID.routeStatus == "route-status")
    }
}
