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
    var isEditingLocked = false
    var onTap: (() -> Void)?

    private var presentation: CardTypePresentation {
        CardTypePresentation.forType(cell.cardType)
    }

    private var visualState: GridCellVisualState {
        GridCellVisualState.make(
            position: cell.position,
            cardType: cell.cardType,
            isSelected: isSelected,
            isEndpoint: isEndpoint,
            isPlayerPosition: isPlayerPosition,
            isActiveResolution: isActiveResolution,
            isEditingLocked: isEditingLocked
        )
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 3) {
                    Image(systemName: roleSymbolName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(roleTint)

                    Image(systemName: presentation.symbolName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(GridPalette.ink)
                        .symbolRenderingMode(.hierarchical)

                    Text(visualState.roleTitle)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(GridPalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text(visualState.cardCode)
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundStyle(GridPalette.ink.opacity(0.85))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            Capsule(style: .continuous)
                                .strokeBorder(GridPalette.ink.opacity(0.55), lineWidth: 1)
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(5)

                if !visualState.markerLabels.filter({ $0 == "Route" || $0 == "End" || $0 == "Here" || $0 == "Now" }).isEmpty {
                    markerStack
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(GridPalette.fill(for: cell.cardType))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                isActiveResolution ? GridPalette.ink.opacity(0.45) : .clear,
                                style: StrokeStyle(lineWidth: 1, dash: [3, 2])
                            )
                    )
            )
            .overlay(alignment: .bottomTrailing) {
                if isPlayerPosition {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(GridPalette.canvas)
                        .padding(3)
                        .background(Circle().strokeBorder(GridPalette.ink, lineWidth: 1).background(Circle().fill(GridPalette.accent)))
                        .padding(3)
                }
            }
            .opacity(visualState.isDimmed ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(GridAccessibilityID.cell(cell.coordinate))
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(
            AccessibilityCopy.cellHint(isInteractive: onTap != nil, isLocked: isEditingLocked)
                ?? "Card on the delivery grid."
        )
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityAddTraits(onTap == nil ? [.isStaticText] : [])
    }

    private var markerStack: some View {
        HStack(spacing: 2) {
            ForEach(visualState.markerLabels.filter { ["Route", "End", "Here", "Now"].contains($0) }, id: \.self) { label in
                Text(label)
                    .font(.system(size: 7, weight: .heavy))
                    .foregroundStyle(GridPalette.canvas)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(
                        Capsule(style: .continuous)
                            .fill(markerFill(for: label))
                    )
            }
        }
        .padding(3)
    }

    private func markerFill(for label: String) -> Color {
        switch label {
        case "Now":
            GridPalette.accent
        case "Here":
            GridPalette.depot
        case "End":
            GridPalette.accent
        default:
            GridPalette.ink.opacity(0.75)
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
            return GridPalette.ink.opacity(0.9)
        }
        switch cell.position {
        case .depot:
            return GridPalette.depot
        case .destination:
            return GridPalette.destination
        case .standard:
            return GridPalette.ink.opacity(0.12)
        }
    }

    private var borderWidth: CGFloat {
        if isActiveResolution || isPlayerPosition || isEndpoint || isSelected || cell.position != .standard {
            return 2.5
        }
        return 1
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
        label += ", code \(visualState.cardCode)"
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
        if isEditingLocked {
            label += ", locked"
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
