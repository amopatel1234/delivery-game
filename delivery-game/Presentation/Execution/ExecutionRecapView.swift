//
//  ExecutionRecapView.swift
//  delivery-game
//

import SwiftUI

/// Scrollable route recap driven by a pure `ExecutionRecap` model.
struct ExecutionRecapView: View {
    let recap: ExecutionRecap

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route recap")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(GridPalette.ink)

            Text(recap.jobDisplayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GridPalette.mutedInk)

            HStack(spacing: 12) {
                summaryChip(title: "Elapsed", value: "\(recap.totalElapsedMinutes) min")
                summaryChip(title: "Delay", value: "\(recap.totalDelayMinutes) min")
                summaryChip(title: "Damage", value: "\(recap.totalDamageEvents)")
            }
            .accessibilityIdentifier(GridAccessibilityID.executionRecapSummary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(recap.entries) { entry in
                    recapRow(entry)
                }
            }
            .accessibilityIdentifier(GridAccessibilityID.executionRecapList)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GridPalette.panel)
        )
        .accessibilityIdentifier(GridAccessibilityID.executionRecap)
        .accessibilityLabel(
            "Route recap for \(recap.jobDisplayName). \(recap.cardCount) cards. Elapsed \(recap.totalElapsedMinutes) minutes. Damage \(recap.totalDamageEvents)."
        )
    }

    private func summaryChip(title: String, value: String) -> some View {
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

    private func recapRow(_ entry: ExecutionRecapEntry) -> some View {
        let presentation = CardTypePresentation.forType(entry.cardType)
        return HStack(alignment: .top, spacing: 10) {
            Text("\(entry.enteredIndex + 1)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(GridPalette.mutedInk)
                .frame(width: 20, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(presentation.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(GridPalette.ink)
                Text(detailLine(for: entry))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(GridPalette.mutedInk)
            }

            Spacer(minLength: 0)
        }
        .accessibilityIdentifier(GridAccessibilityID.executionRecapEntry(entry.enteredIndex))
        .accessibilityLabel(rowAccessibilityLabel(entry, title: presentation.title))
    }

    private func detailLine(for entry: ExecutionRecapEntry) -> String {
        var parts = ["Move \(entry.movementMinutes) min"]
        if entry.delayMinutes > 0 {
            parts.append("Delay \(entry.delayMinutes) min")
        }
        if entry.didDamage {
            parts.append("Damage")
        }
        return parts.joined(separator: " · ")
    }

    private func rowAccessibilityLabel(_ entry: ExecutionRecapEntry, title: String) -> String {
        var label = "Card \(entry.enteredIndex + 1), \(title), move \(entry.movementMinutes) minutes"
        if entry.delayMinutes > 0 {
            label += ", delay \(entry.delayMinutes) minutes"
        }
        if entry.didDamage {
            label += ", damage"
        }
        return label
    }
}
