//
//  CardType.swift
//  delivery-game
//

import Foundation

/// Stable identifiers for every MVP card type.
/// Raw values are persistence/testing keys and must remain stable.
nonisolated enum CardType: String, CaseIterable, Codable, Sendable, Hashable {
    case clearRoad = "clear_road"
    case lightTraffic = "light_traffic"
    case heavyTraffic = "heavy_traffic"
    case roadworks = "roadworks"
    case fastLane = "fast_lane"
}
