//
//  ExecutionProgressView.swift
//  delivery-game
//

import SwiftUI

/// Live execution HUD driven by a pure presentation snapshot.
/// Never mutates execution results.
struct ExecutionProgressView: View {
    let presentation: ExecutionPresentationState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleText)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(GridPalette.ink)

            Text(presentation.jobDisplayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GridPalette.mutedInk)

            Text(presentation.statusMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(GridPalette.ink)
                .accessibilityIdentifier(GridAccessibilityID.executionStatus)

            HStack(spacing: 16) {
                metric(title: "Progress", value: presentation.progressLabel)
                    .accessibilityIdentifier(GridAccessibilityID.executionProgress)
                metric(title: "Elapsed", value: "\(presentation.elapsedMinutes) min")
                    .accessibilityIdentifier(GridAccessibilityID.executionElapsed)
                metric(title: "Damage", value: "\(presentation.damageEventCount)")
                    .accessibilityIdentifier(GridAccessibilityID.executionDamage)
            }

            if let consequence = presentation.lastConsequence {
                Text(consequenceCaption(consequence))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(consequenceColor(consequence))
                    .accessibilityIdentifier(GridAccessibilityID.executionConsequence)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GridPalette.panel)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(GridAccessibilityID.executionProgressPanel)
        .accessibilityLabel(presentation.accessibilityLabel)
    }

    private var titleText: String {
        switch presentation.phase {
        case .ready:
            "Route confirmed"
        case .running:
            "Executing route"
        case .completed:
            "Route executed"
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(GridPalette.mutedInk)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(GridPalette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func consequenceCaption(_ kind: ExecutionConsequenceKind) -> String {
        switch kind {
        case .movement:
            "Last card: normal movement"
        case .delay:
            "Last card: delay applied"
        case .damage:
            "Last card: damage event"
        }
    }

    private func consequenceColor(_ kind: ExecutionConsequenceKind) -> Color {
        switch kind {
        case .movement:
            GridPalette.depot
        case .delay:
            GridPalette.accent
        case .damage:
            GridPalette.destination
        }
    }
}
