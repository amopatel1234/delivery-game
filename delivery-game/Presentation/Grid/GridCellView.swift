//
//  GridCellView.swift
//  delivery-game
//

import SwiftUI

/// Renders one grid cell from explicit inputs.
/// Independent of board layout, menu, navigation, and route rules.
struct GridCellView: View {
    let cell: GridCell
    var isSelected = false
    var isEndpoint = false
    var isPlayerPosition = false
    var isActiveResolution = false
    var onTap: (() -> Void)?

    private var presentation: CardTypePresentation {
        CardTypePresentation.forType(cell.cardType)
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: roleSymbolName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(roleTint)

                Image(systemName: presentation.symbolName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(GridPalette.ink)

                Text(shortLabel)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(GridPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(GridPalette.fill(for: cell.cardType))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .overlay(alignment: .topTrailing) {
                if isPlayerPosition {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(GridPalette.ink)
                        .padding(4)
                        .background(Circle().fill(GridPalette.accent))
                        .padding(4)
                }
            }
            .opacity(isSelected || cell.position != .standard || isPlayerPosition || isActiveResolution ? 1 : 0.92)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(GridAccessibilityID.cell(cell.coordinate))
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var shortLabel: String {
        switch cell.position {
        case .depot:
            "Depot"
        case .destination:
            "Dest"
        case .standard:
            presentation.title
        }
    }

    private var roleSymbolName: String {
        switch cell.position {
        case .depot:
            "house.fill"
        case .destination:
            "flag.checkered"
        case .standard:
            "square.grid.2x2"
        }
    }

    private var roleTint: Color {
        switch cell.position {
        case .depot:
            GridPalette.depot
        case .destination:
            GridPalette.destination
        case .standard:
            GridPalette.mutedInk
        }
    }

    private var borderColor: Color {
        if isActiveResolution {
            return GridPalette.accent
        }
        if isPlayerPosition {
            return GridPalette.depot
        }
        if isEndpoint {
            return GridPalette.accent
        }
        if isSelected {
            return GridPalette.ink.opacity(0.85)
        }
        switch cell.position {
        case .depot:
            return GridPalette.depot
        case .destination:
            return GridPalette.destination
        case .standard:
            return .clear
        }
    }

    private var borderWidth: CGFloat {
        if isActiveResolution || isPlayerPosition || isEndpoint || isSelected || cell.position != .standard {
            return 2
        }
        return 0
    }

    private var accessibilityLabel: String {
        var label: String
        switch cell.position {
        case .depot:
            label = "Depot, \(presentation.accessibilityLabel)"
        case .destination:
            label = "Destination, \(presentation.accessibilityLabel)"
        case .standard:
            label = presentation.accessibilityLabel
        }
        if isActiveResolution {
            label += ", resolving"
        }
        if isPlayerPosition {
            label += ", player position"
        }
        if isEndpoint {
            label += ", route endpoint"
        } else if isSelected {
            label += ", on route"
        }
        return label
    }
}

#Preview("Standard cell") {
    GridCellView(
        cell: GridCell(
            coordinate: GridCoordinate(row: 1, column: 2),
            cardType: .heavyTraffic
        )
    )
    .frame(width: 72, height: 72)
    .padding()
    .background(GridPalette.canvas)
}

#Preview("Selected endpoint") {
    GridCellView(
        cell: GridCell(coordinate: .depot, cardType: .clearRoad),
        isSelected: true,
        isEndpoint: true
    )
    .frame(width: 72, height: 72)
    .padding()
    .background(GridPalette.canvas)
}
