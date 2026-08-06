//
//  OnboardingView.swift
//  delivery-game
//

import SwiftUI

/// First-run guidance through the core gameplay loop. Skipable.
struct OnboardingView: View {
    let pages: [OnboardingPage]
    let onFinished: () -> Void

    @State private var pageIndex = 0

    init(
        pages: [OnboardingPage] = OnboardingContent.pages,
        onFinished: @escaping () -> Void
    ) {
        self.pages = pages
        self.onFinished = onFinished
    }

    private var isLastPage: Bool {
        pageIndex >= pages.count - 1
    }

    private var currentPage: OnboardingPage {
        pages[pageIndex]
    }

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button("Skip") {
                    onFinished()
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(GridPalette.mutedInk)
                .accessibilityIdentifier(GridAccessibilityID.onboardingSkipButton)
                .accessibilityLabel(AccessibilityCopy.skipOnboardingLabel)
                .accessibilityHint(AccessibilityCopy.skipOnboardingHint)
            }

            Spacer(minLength: 0)

            Image(systemName: currentPage.symbolName)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(GridPalette.accent)
                .accessibilityHidden(true)

            Text(currentPage.title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(GridPalette.ink)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier(GridAccessibilityID.onboardingTitle)

            Text(currentPage.body)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(GridPalette.mutedInk)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier(GridAccessibilityID.onboardingBody)

            pageIndicators

            Spacer(minLength: 0)

            Button(action: advanceOrFinish) {
                Text(isLastPage ? "Get Started" : "Next")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(GridPalette.canvas)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(GridPalette.accent)
                    )
            }
            .accessibilityIdentifier(GridAccessibilityID.onboardingPrimaryButton)
            .accessibilityLabel(isLastPage ? "Get started" : "Next onboarding page")
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GridPalette.canvas.ignoresSafeArea())
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .accessibilityIdentifier(GridAccessibilityID.onboarding)
        .accessibilityLabel(
            "Onboarding page \(pageIndex + 1) of \(pages.count). \(currentPage.title). \(currentPage.body)"
        )
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Circle()
                    .fill(index == pageIndex ? GridPalette.accent : GridPalette.mutedInk.opacity(0.35))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityIdentifier(GridAccessibilityID.onboardingPageIndicator)
        .accessibilityLabel("Page \(pageIndex + 1) of \(pages.count)")
    }

    private func advanceOrFinish() {
        if isLastPage {
            onFinished()
        } else {
            pageIndex += 1
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingView(onFinished: {})
    }
}
