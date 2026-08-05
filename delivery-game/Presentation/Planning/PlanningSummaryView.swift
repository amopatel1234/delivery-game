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
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(GridPalette.ink)

            ForEach(summary.metrics) { metric in
                HStack {
                    Text(metric.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(GridPalette.mutedInk)

                    Spacer()

                    Text(metric.value)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(metric.isAvailable ? GridPalette.ink : GridPalette.mutedInk)
                }
                .accessibilityIdentifier(GridAccessibilityID.planningMetric(metric.id))
            }
        }
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
            job: try! SeededJobCatalogue.loadDefault()
        )
    )
    .padding()
    .background(GridPalette.canvas)
}
