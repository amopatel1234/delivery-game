//
//  GridCellVisualState.swift
//  delivery-game
//

import Foundation

/// Non-colour markers that distinguish cell interaction / execution states.
nonisolated enum GridCellMarkerKind: String, Equatable, Sendable {
    case depot
    case destination
    case onRoute
    case endpoint
    case player
    case resolving
}

/// Presentation-neutral description of how a grid cell should look.
nonisolated struct GridCellVisualState: Equatable, Sendable {
    let cardCode: String
    let roleTitle: String
    let markers: [GridCellMarkerKind]
    let isDimmed: Bool
    let showsRouteChrome: Bool

    var markerLabels: [String] {
        markers.map { marker in
            switch marker {
            case .depot: "Depot"
            case .destination: "Dest"
            case .onRoute: "Route"
            case .endpoint: "End"
            case .player: "Here"
            case .resolving: "Now"
            }
        }
    }

    static func make(
        position: GridPosition,
        cardType: CardType,
        isSelected: Bool,
        isEndpoint: Bool,
        isPlayerPosition: Bool,
        isActiveResolution: Bool,
        isEditingLocked: Bool
    ) -> GridCellVisualState {
        let presentation = CardTypePresentation.forType(cardType)
        var markers: [GridCellMarkerKind] = []

        switch position {
        case .depot:
            markers.append(.depot)
        case .destination:
            markers.append(.destination)
        case .standard:
            break
        }

        if isSelected {
            markers.append(.onRoute)
        }
        if isEndpoint {
            markers.append(.endpoint)
        }
        if isPlayerPosition {
            markers.append(.player)
        }
        if isActiveResolution {
            markers.append(.resolving)
        }

        let roleTitle: String
        switch position {
        case .depot:
            roleTitle = "Depot"
        case .destination:
            roleTitle = "Destination"
        case .standard:
            roleTitle = presentation.title
        }

        let dimmed = isEditingLocked && !isSelected && !isPlayerPosition && !isActiveResolution
            && position == .standard

        return GridCellVisualState(
            cardCode: presentation.shortCode,
            roleTitle: roleTitle,
            markers: markers,
            isDimmed: dimmed,
            showsRouteChrome: isSelected || isEndpoint || isPlayerPosition || isActiveResolution
        )
    }
}
