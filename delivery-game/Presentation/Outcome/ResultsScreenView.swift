//
//  ResultsScreenView.swift
//  delivery-game
//

import SwiftUI

/// Presents completed or failed delivery outcome, payout breakdown and route recap.
struct ResultsScreenView: View {
    let input: ResultsScreenInput
    let onContinue: () -> Void

    private var presentation: ResultsScreenPresentation {
        ResultsScreenPresentation.make(from: input)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                rewardPanel
                timingPanel
                breakdownPanel
                ExecutionRecapView(recap: input.recap)
                continueButton
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GridPalette.canvas.ignoresSafeArea())
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(GridAccessibilityID.resultsScreen)
        .accessibilityLabel(presentation.accessibilityLabel)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: presentation.headingTone == .completed ? "checkmark.seal.fill" : "xmark.octagon.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(headingColor)
                Text(presentation.heading)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(headingColor)
                    .accessibilityIdentifier(GridAccessibilityID.resultsHeading)
            }

            Text(presentation.headingTone == .completed ? "STATUS: COMPLETED" : "STATUS: FAILED")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(GridPalette.canvas)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(headingColor)
                )
                .accessibilityLabel(
                    presentation.headingTone == .completed ? "Status completed" : "Status failed"
                )

            Text(presentation.jobDisplayName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(GridPalette.mutedInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rewardPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(presentation.rewardCaption)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(GridPalette.mutedInk)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(presentation.rewardAmount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(rewardColor)
                Text("coins")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GridPalette.mutedInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GridPalette.panel)
        )
        .accessibilityIdentifier(GridAccessibilityID.resultsReward)
        .accessibilityLabel(
            "\(presentation.rewardCaption). \(presentation.rewardAmount) coins."
        )
    }

    private var timingPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Timing")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(GridPalette.ink)

            ForEach(presentation.timingRows) { row in
                HStack {
                    Text(row.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(GridPalette.mutedInk)
                    Spacer()
                    Text(row.value)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GridPalette.ink)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.accessibilityLabel)
                .accessibilityIdentifier(GridAccessibilityID.resultsTimingRow(row.id))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GridPalette.panel)
        )
        .accessibilityIdentifier(GridAccessibilityID.resultsTiming)
    }

    private var breakdownPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Payout breakdown")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(GridPalette.ink)

            ForEach(presentation.breakdownRows) { row in
                HStack {
                    Text(row.title)
                        .font(
                            .system(
                                size: row.isEmphasized ? 15 : 14,
                                weight: row.isEmphasized ? .bold : .medium,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(row.isEmphasized ? GridPalette.ink : GridPalette.mutedInk)
                    Spacer()
                    Text(row.value)
                        .font(
                            .system(
                                size: row.isEmphasized ? 16 : 14,
                                weight: .semibold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(breakdownValueColor(for: row))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.accessibilityLabel)
                .accessibilityIdentifier(GridAccessibilityID.resultsBreakdownRow(row.id))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GridPalette.panel)
        )
        .accessibilityIdentifier(GridAccessibilityID.resultsBreakdown)
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Label("Continue", systemImage: "arrow.right.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(GridPalette.canvas)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(GridPalette.accent)
                )
        }
        .accessibilityIdentifier(GridAccessibilityID.resultsContinueButton)
        .accessibilityLabel(AccessibilityCopy.continueLabel)
        .accessibilityHint(AccessibilityCopy.continueHint)
    }

    private var headingColor: Color {
        presentation.headingTone == .completed ? GridPalette.depot : GridPalette.destination
    }

    private var rewardColor: Color {
        presentation.headingTone == .completed ? GridPalette.ink : GridPalette.mutedInk
    }

    private func breakdownValueColor(for row: ResultsBreakdownRow) -> Color {
        if row.isEmphasized {
            return presentation.headingTone == .completed ? GridPalette.depot : GridPalette.destination
        }
        if row.isDeduction, row.value != "0" {
            return GridPalette.destination
        }
        if row.value.hasPrefix("+"), row.value != "+0" {
            return GridPalette.depot
        }
        return GridPalette.ink
    }
}

#Preview("Completed") {
    NavigationStack {
        ResultsScreenView(
            input: ResultsScreenInput(
                jobDisplayName: "Job 1",
                breakdown: OutcomeBreakdownBuilder.build(
                    from: RewardSettler.settle(
                        evaluation: OutcomeEvaluator.evaluate(
                            elapsedMinutes: 8,
                            targetTimeMinutes: 10,
                            deadlineMinutes: 16
                        ),
                        economy: .mvp
                    )
                ),
                recap: ExecutionRecap(
                    jobID: SeededJobCatalogue.defaultJobID,
                    jobDisplayName: "Job 1",
                    targetTimeMinutes: 10,
                    deadlineMinutes: 16,
                    entries: [],
                    totalBaseTravelMinutes: 7,
                    totalDelayMinutes: 1,
                    totalElapsedMinutes: 8,
                    totalDamageEvents: 0,
                    delayedCardCount: 1
                )
            ),
            onContinue: {}
        )
    }
}
