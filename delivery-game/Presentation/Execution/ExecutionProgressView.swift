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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(titleText)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(GridPalette.ink)
                Spacer()
                phaseBadge
            }

            Text(presentation.jobDisplayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GridPalette.mutedInk)

            Text(presentation.statusMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(GridPalette.ink)
                .accessibilityIdentifier(GridAccessibilityID.executionStatus)

            ProgressView(value: presentation.progressFraction)
                .tint(GridPalette.accent)
                .accessibilityLabel("Execution progress \(presentation.progressLabel)")

            HStack(spacing: 16) {
                metric(title: "Progress", value: presentation.progressLabel, symbol: "list.number")
                    .accessibilityIdentifier(GridAccessibilityID.executionProgress)
                metric(title: "Elapsed", value: "\(presentation.elapsedMinutes) min", symbol: "clock")
                    .accessibilityIdentifier(GridAccessibilityID.executionElapsed)
                metric(title: "Damage", value: "\(presentation.damageEventCount)", symbol: "wrench.and.screwdriver")
                    .accessibilityIdentifier(GridAccessibilityID.executionDamage)
            }

            if let consequence = presentation.lastConsequence {
                HStack(spacing: 8) {
                    Image(systemName: consequenceSymbol(consequence))
                        .font(.system(size: 12, weight: .bold))
                    Text(consequenceCaption(consequence))
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(consequenceColor(consequence))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .strokeBorder(consequenceColor(consequence).opacity(0.55), lineWidth: 1)
                        .background(Capsule().fill(consequenceColor(consequence).opacity(0.12)))
                )
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

    private var phaseBadge: some View {
        Text(presentation.phase.rawValue.capitalized)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(GridPalette.canvas)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(phaseBadgeColor)
            )
            .accessibilityLabel("Phase \(presentation.phase.rawValue)")
    }

    private var phaseBadgeColor: Color {
        switch presentation.phase {
        case .ready:
            GridPalette.mutedInk
        case .running:
            GridPalette.accent
        case .completed:
            GridPalette.depot
        }
    }

    private func metric(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(GridPalette.mutedInk)
                .labelStyle(.titleAndIcon)
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

    private func consequenceSymbol(_ kind: ExecutionConsequenceKind) -> String {
        switch kind {
        case .movement:
            "arrow.right"
        case .delay:
            "clock.badge.exclamationmark"
        case .damage:
            "exclamationmark.triangle.fill"
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
