//
//  GridPalette.swift
//  delivery-game
//

import SwiftUI

/// Placeholder visual tokens for the prototype grid.
/// Views depend on this palette, not on each other.
enum GridPalette {
    static let canvas = Color(red: 0.10, green: 0.14, blue: 0.18)
    static let panel = Color(red: 0.14, green: 0.19, blue: 0.24)
    static let ink = Color(red: 0.93, green: 0.95, blue: 0.97)
    static let mutedInk = Color(red: 0.70, green: 0.76, blue: 0.82)
    static let accent = Color(red: 0.98, green: 0.62, blue: 0.22)
    static let depot = Color(red: 0.20, green: 0.70, blue: 0.55)
    static let destination = Color(red: 0.95, green: 0.35, blue: 0.38)

    static func fill(for type: CardType) -> Color {
        switch type {
        case .clearRoad:
            Color(red: 0.30, green: 0.55, blue: 0.42)
        case .lightTraffic:
            Color(red: 0.85, green: 0.68, blue: 0.25)
        case .heavyTraffic:
            Color(red: 0.78, green: 0.32, blue: 0.28)
        case .roadworks:
            Color(red: 0.80, green: 0.48, blue: 0.18)
        case .fastLane:
            Color(red: 0.28, green: 0.58, blue: 0.88)
        }
    }
}
