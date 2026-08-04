//
//  GridCellView.swift
//  delivery-game
//

import SwiftUI

/// Renders one grid cell from explicit inputs.
/// Independent of board layout, menu, and navigation.
struct GridCellView: View {
    let cell: GridCell

    private var presentation: CardTypePresentation {
        CardTypePresentation.forType(cell.cardType)
    }

    var body: some View {
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
                .strokeBorder(roleBorderColor, lineWidth: cell.position == .standard ? 0 : 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(GridAccessibilityID.cell(cell.coordinate))
        .accessibilityLabel(accessibilityLabel)
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

    private var roleBorderColor: Color {
        switch cell.position {
        case .depot:
            GridPalette.depot
        case .destination:
            GridPalette.destination
        case .standard:
            .clear
        }
    }

    private var accessibilityLabel: String {
        switch cell.position {
        case .depot:
            "Depot, \(presentation.accessibilityLabel)"
        case .destination:
            "Destination, \(presentation.accessibilityLabel)"
        case .standard:
            presentation.accessibilityLabel
        }
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

#Preview("Depot cell") {
    GridCellView(
        cell: GridCell(coordinate: .depot, cardType: .clearRoad)
    )
    .frame(width: 72, height: 72)
    .padding()
    .background(GridPalette.canvas)
}
