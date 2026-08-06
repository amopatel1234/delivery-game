//
//  PlanningSummaryView.swift
//  delivery-game
//

import SwiftUI

/// Displays planning metrics from a presentation-neutral input.
struct PlanningSummaryView: View {
    let summary: PlanningSummaryInput

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Planning summary")
                .font(.headline.weight(.bold))
                .foregroundStyle(GridPalette.ink)

            ForEach(summary.metrics) { metric in
                HStack {
                    Text(metric.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(GridPalette.mutedInk)

                    Spacer()

                    Text(metric.value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(metric.isAvailable ? GridPalette.ink : GridPalette.mutedInk)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(metric.accessibilityLabel)
                .accessibilityIdentifier(GridAccessibilityID.planningMetric(metric.id))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GridPalette.panel)
        )
        .accessibilityIdentifier(GridAccessibilityID.planningSummary)
    }
}

#Preview {
    PlanningSummaryView(
        summary: PlanningSummaryInput.from(
            job: try! SeededJobCatalogue.loadDefault(),
            route: RouteBuilder().route,
            grid: try! DeliveryGrid(board: try! SeededJobCatalogue.loadDefault().board)
        )
    )
    .padding()
    .background(GridPalette.canvas)
}
