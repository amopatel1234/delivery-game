//
//  AppRoute.swift
//  delivery-game
//

import Foundation

/// Lightweight navigation destinations for the prototype shell.
enum AppRoute: Hashable {
    case onboarding
    case planning(SeededJobID)
    case results(ResultsScreenInput)
    case jobSelection(availableJobs: [SeededJobID])
}
