//
//  GameBoardScreen.swift
//  delivery-game
//

import SwiftUI

/// Thin screen that loads a seeded job and hosts `GridBoardView`.
/// Keeps navigation/loading concerns out of the reusable grid views.
struct GameBoardScreen: View {
    let jobID: SeededJobID

    @State private var grid: DeliveryGrid?
    @State private var loadErrorMessage: String?

    init(jobID: SeededJobID = SeededJobCatalogue.defaultJobID) {
        self.jobID = jobID
    }

    var body: some View {
        Group {
            if let grid {
                VStack(spacing: 16) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(GridPalette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    GridBoardView(grid: grid)
                        .aspectRatio(1, contentMode: .fit)

                    Spacer(minLength: 0)
                }
                .padding(16)
            } else if let loadErrorMessage {
                Text(loadErrorMessage)
                    .foregroundStyle(GridPalette.destination)
                    .padding()
            } else {
                ProgressView()
                    .tint(GridPalette.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GridPalette.canvas.ignoresSafeArea())
        .navigationTitle("Board")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: jobID) {
            loadBoard()
        }
    }

    private var title: String {
        SeededJobCatalogue.definition(for: jobID).displayName
    }

    private func loadBoard() {
        do {
            let job = try SeededJobCatalogue.load(id: jobID)
            grid = try DeliveryGrid(board: job.board)
            loadErrorMessage = nil
        } catch {
            grid = nil
            loadErrorMessage = "Could not load board."
        }
    }
}

#Preview {
    NavigationStack {
        GameBoardScreen()
    }
}
