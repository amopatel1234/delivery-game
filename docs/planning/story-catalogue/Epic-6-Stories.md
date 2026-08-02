# Epic 6 – Polish, Validation and TestFlight

## E6-S01 — First-Time User Experience

### Goal

Guide a first-time player through the core gameplay loop with minimal friction.

### Deliverable

Onboarding Flow

### Scope

- First-launch experience.
- Core gameplay explanation.
- Route construction guidance.
- Target Time and Deadline explanation.
- Risk explanation.
- Onboarding completion state.

### Out of Scope

- Tutorial levels.
- Gameplay changes.

### Dependencies

- E4-S06.

### Acceptance Criteria

- First-time users can complete a delivery without external guidance.
- Onboarding may be skipped.
- Completion state persists.
- Development builds can reset onboarding.

### References

- [Epic 6](../../epics/Epic-6-Polish-and-TestFlight.md)
- [Gameplay Rules](../../Gameplay-Rules.md)

## E6-S02 — Gameplay Polish

### Goal

Improve the visual quality and responsiveness of the gameplay experience without changing gameplay behaviour.

### Deliverable

Gameplay Presentation

### Scope

- Card presentation.
- Grid styling.
- Route highlighting.
- Execution feedback.
- Results presentation.

### Out of Scope

- New gameplay.
- New mechanics.

### Dependencies

- E6-S01.

### Acceptance Criteria

- Gameplay remains visually consistent.
- States are clearly distinguishable.
- Layout remains stable.
- Gameplay behaviour is unchanged.

### References

- [Epic 6](../../epics/Epic-6-Polish-and-TestFlight.md)

## E6-S03 — Accessibility

### Goal

Ensure the MVP is fully usable with the supported iOS accessibility features.

### Deliverable

Accessibility Support

### Scope

- VoiceOver.
- Dynamic Type.
- Reduce Motion.
- Accessibility identifiers.
- Contrast validation.

### Out of Scope

- Gameplay changes.

### Dependencies

- E6-S02.

### Acceptance Criteria

- Interactive controls expose accessibility labels.
- Dynamic Type remains usable.
- Reduce Motion is respected.
- VoiceOver communicates gameplay correctly.

### References

- [Epic 6](../../epics/Epic-6-Polish-and-TestFlight.md)

## E6-S04 — MVP Validation

### Goal

Validate that the five seeded jobs achieve the intended design goals before external testing.

### Deliverable

Internal Validation

### Scope

- Seed verification.
- Balance review.
- Alternative route testing.
- Regression testing.
- Internal playtesting.

### Out of Scope

- External feedback.

### Dependencies

- E6-S03.

### Acceptance Criteria

- Every seeded job remains valid.
- No dominant unintended strategy exists.
- Accepted layouts remain deterministic.
- Regression tests pass.

### References

- [Epic 5](../../epics/Epic-5-Deck-and-Card-Generation.md)
- [Epic 6](../../epics/Epic-6-Polish-and-TestFlight.md)

## E6-S05 — TestFlight Release

### Goal

Produce and distribute a stable external TestFlight build.

### Deliverable

TestFlight Build

### Scope

- Signing.
- Versioning.
- Release archive.
- Internal testing.
- External testing.
- App Store Connect configuration.

### Out of Scope

- App Store release.

### Dependencies

- E6-S04.

### Acceptance Criteria

- Release archive uploads successfully.
- Internal testing passes.
- External TestFlight is available.
- Release notes are prepared.

### References

- [Epic 6](../../epics/Epic-6-Polish-and-TestFlight.md)

## E6-S06 — MVP Evaluation

### Goal

Collect structured feedback and determine whether the MVP has successfully validated the core gameplay loop.

### Deliverable

MVP Validation Report

### Scope

- Player feedback.
- Route-choice analysis.
- Gameplay observations.
- Success criteria review.
- Recommendation for next phase.

### Out of Scope

- Feature development.

### Dependencies

- E6-S05.

### Acceptance Criteria

- Feedback is collected from external testers.
- MVP success criteria are evaluated.
- Strengths and weaknesses are documented.
- Recommendation is produced for the next phase.

### References

- [PRD](../../PRD.md)
- [Roadmap](../../Roadmap.md)
- [Epic 6](../../epics/Epic-6-Polish-and-TestFlight.md)

---
