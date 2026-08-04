//
//  GridBoardView.swift
//  delivery-game
//

import SwiftUI

/// Renders a full delivery grid from a `DeliveryGrid` value.
/// Independent of menu/navigation; pass any grid to preview or embed it.
struct GridBoardView: View {
    let grid: DeliveryGrid

    private let spacing: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let cellSide = availableCellSide(in: side)

            VStack(spacing: spacing) {
                ForEach(0 ..< DeliveryGrid.size, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0 ..< DeliveryGrid.size, id: \.self) { column in
                            let coordinate = GridCoordinate(row: row, column: column)
                            GridCellView(cell: grid.cell(at: coordinate))
                                .frame(width: cellSide, height: cellSide)
                        }
                    }
                }
            }
            .frame(width: side, height: side, alignment: .center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityIdentifier(GridAccessibilityID.board)
    }

    private func availableCellSide(in boardSide: CGFloat) -> CGFloat {
        let totalSpacing = spacing * CGFloat(DeliveryGrid.size - 1)
        return max((boardSide - totalSpacing) / CGFloat(DeliveryGrid.size), 1)
    }
}

#Preview("Seeded board") {
    GridBoardView(grid: (try? DeliveryGrid(board: BoardGenerator.generate(seed: 1001)))!)
        .padding()
        .background(GridPalette.canvas)
}
