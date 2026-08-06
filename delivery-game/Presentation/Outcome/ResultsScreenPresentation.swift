//
//  ResultsScreenPresentation.swift
//  delivery-game
//

import Foundation

/// Visual tone for the results heading.
nonisolated enum ResultsHeadingTone: String, Equatable, Sendable {
    case completed
    case failed
}

/// One timing comparison row on the results screen.
nonisolated struct ResultsTimingRow: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let value: String
    let accessibilityLabel: String
}

/// One payout breakdown row on the results screen.
nonisolated struct ResultsBreakdownRow: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let value: String
    let isDeduction: Bool
    let isEmphasized: Bool
    let accessibilityLabel: String
}

/// SwiftUI-free mapping from `ResultsScreenInput` to display strings.
nonisolated struct ResultsScreenPresentation: Equatable, Sendable {
    let jobDisplayName: String
    let heading: String
    let headingTone: ResultsHeadingTone
    let rewardAmount: Int
    let rewardCaption: String
    let timingRows: [ResultsTimingRow]
    let breakdownRows: [ResultsBreakdownRow]
    let accessibilityLabel: String

    static func make(from input: ResultsScreenInput) -> ResultsScreenPresentation {
        let breakdown = input.breakdown
        let headingTone: ResultsHeadingTone = breakdown.isFailed ? .failed : .completed
        let heading = breakdown.isFailed ? "Delivery failed" : "Delivery complete"
        let rewardCaption = breakdown.isFailed ? "No reward earned" : "Reward earned"

        let timingRows = [
            ResultsTimingRow(
                id: "actual",
                title: "Actual time",
                value: "\(breakdown.elapsedMinutes) min",
                accessibilityLabel: "Actual time \(breakdown.elapsedMinutes) minutes"
            ),
            ResultsTimingRow(
                id: "target",
                title: "Target time",
                value: "\(breakdown.targetTimeMinutes) min",
                accessibilityLabel: "Target time \(breakdown.targetTimeMinutes) minutes"
            ),
            ResultsTimingRow(
                id: "deadline",
                title: "Deadline",
                value: "\(breakdown.deadlineMinutes) min",
                accessibilityLabel: "Deadline \(breakdown.deadlineMinutes) minutes"
            ),
            ResultsTimingRow(
                id: "damage",
                title: "Damage events",
                value: "\(breakdown.damageEventCount)",
                accessibilityLabel: "Damage events \(breakdown.damageEventCount)"
            ),
        ]

        let breakdownRows = breakdown.rewardLineItems.map { item in
            ResultsBreakdownRow(
                id: item.kind.rawValue,
                title: title(for: item),
                value: formattedAmount(for: item),
                isDeduction: item.isDeduction,
                isEmphasized: item.kind == .finalReward,
                accessibilityLabel: breakdownAccessibilityLabel(for: item)
            )
        }

        let accessibilityLabel =
            "\(heading). \(rewardCaption) \(breakdown.finalReward) coins. "
            + "Actual time \(breakdown.elapsedMinutes) minutes. "
            + "Target \(breakdown.targetTimeMinutes) minutes. "
            + "Deadline \(breakdown.deadlineMinutes) minutes."

        return ResultsScreenPresentation(
            jobDisplayName: input.jobDisplayName,
            heading: heading,
            headingTone: headingTone,
            rewardAmount: breakdown.finalReward,
            rewardCaption: rewardCaption,
            timingRows: timingRows,
            breakdownRows: breakdownRows,
            accessibilityLabel: accessibilityLabel
        )
    }

    private static func title(for item: OutcomeBreakdownLineItem) -> String {
        switch item.kind {
        case .baseReward:
            "Base reward"
        case .earlyBonus:
            if let quantity = item.quantity {
                "Early bonus (\(quantity) min)"
            } else {
                "Early bonus"
            }
        case .latenessPenalty:
            if let quantity = item.quantity {
                "Late penalty (\(quantity) min)"
            } else {
                "Late penalty"
            }
        case .damagePenalty:
            if let quantity = item.quantity {
                "Damage penalty (\(quantity))"
            } else {
                "Damage penalty"
            }
        case .finalReward:
            "Final reward"
        }
    }

    private static func formattedAmount(for item: OutcomeBreakdownLineItem) -> String {
        if item.kind == .finalReward {
            return "\(item.amount)"
        }
        if item.isDeduction {
            return item.amount == 0 ? "0" : "-\(item.amount)"
        }
        return item.amount == 0 ? "0" : "+\(item.amount)"
    }

    private static func breakdownAccessibilityLabel(for item: OutcomeBreakdownLineItem) -> String {
        let title = title(for: item)
        if item.kind == .finalReward {
            return "\(title) \(item.amount) coins"
        }
        if item.isDeduction {
            return "\(title) minus \(item.amount) coins"
        }
        return "\(title) plus \(item.amount) coins"
    }
}
