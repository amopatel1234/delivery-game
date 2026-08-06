//
//  JobSelectionView.swift
//  delivery-game
//

import SwiftUI

/// Lets the player replay any authored job after completing the sequential run.
struct JobSelectionView: View {
    let availableJobs: [SeededJobID]
    let onSelectJob: (SeededJobID) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose a job")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(GridPalette.ink)

                Text("Replay any seeded job to compare routes.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(GridPalette.mutedInk)

                VStack(spacing: 10) {
                    ForEach(availableJobs, id: \.self) { jobID in
                        jobButton(for: jobID)
                    }
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GridPalette.canvas.ignoresSafeArea())
        .navigationTitle("Replay")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .accessibilityIdentifier(GridAccessibilityID.jobSelection)
        .accessibilityLabel("Replay job selection")
    }

    private func jobButton(for jobID: SeededJobID) -> some View {
        let definition = SeededJobCatalogue.definition(for: jobID)
        return Button {
            onSelectJob(jobID)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(definition.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(GridPalette.ink)
                    Text(
                        "Target \(definition.targetTimeMinutes) min · Deadline \(definition.deadlineMinutes) min"
                    )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(GridPalette.mutedInk)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GridPalette.mutedInk)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(GridPalette.panel)
            )
        }
        .accessibilityIdentifier(GridAccessibilityID.jobSelectionOption(jobID))
        .accessibilityLabel(
            "Replay \(definition.displayName). Target \(definition.targetTimeMinutes) minutes. Deadline \(definition.deadlineMinutes) minutes."
        )
    }
}

#Preview {
    NavigationStack {
        JobSelectionView(availableJobs: SeededJobCatalogue.sequentialOrder) { _ in }
    }
}
