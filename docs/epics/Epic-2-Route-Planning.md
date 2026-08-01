# Epic 2 – Route Planning

## Goal

Turn the route built on the grid into a complete planning experience by calculating and presenting the consequences of the selected path before execution begins.

This epic gives the player enough information to compare routes without recommending an optimal choice.

## Scope

This epic includes:

- Route-derived planning calculations.
- Estimated arrival time.
- Target Time and Deadline presentation.
- Delay-exposure classification.
- Damage-risk classification.
- Maximum achievable reward preview.
- Live recalculation as the route changes.
- Clear distinction between deterministic values and estimates.

Execution, random outcome resolution and final payout settlement are out of scope.

## Player Experience

As the player adds or removes cards, planning information updates immediately.

The player should be able to compare routes by understanding:

- how long the route is expected to take;
- how much delay exposure it contains;
- how much damage risk it contains;
- the maximum reward available if the route resolves without avoidable penalties.

The game must remain neutral. It must not highlight, rank or recommend a best route.

## Functional Requirements

### Estimated Arrival

- Calculate estimated arrival from the selected route.
- Include deterministic card travel time.
- Exclude unresolved random outcomes from the estimate unless explicitly represented by the accepted planning model.
- Label the value as approximate.
- Recalculate whenever the route changes.

### Job Timing

- Display the active job's Target Time.
- Display the active job's Deadline.
- Treat Target Time and Deadline as separate values.
- Make the difference between bonus eligibility and failure or lateness pressure clear in the UI.

### Delay Exposure

- Derive delay exposure from the selected route.
- Present the result as Low, Medium or High.
- Base the classification on route composition rather than player performance.
- Recalculate after every route change.

### Damage Risk

- Derive damage risk from the selected route.
- Present the result as Low, Medium or High.
- Keep damage risk separate from delay exposure.
- Recalculate after every route change.

### Maximum Reward Preview

- Calculate the maximum achievable reward for the current route.
- Use deterministic route values and the accepted economy rules.
- Do not present expected payout.
- Update the preview whenever the route changes.

### Planning Summary

Present the following together in a stable planning summary:

- estimated arrival;
- target time;
- deadline;
- delay exposure;
- damage risk;
- maximum achievable reward.

The summary must remain visible or easily accessible while planning.

## Out of Scope

- Card-effect resolution.
- Random-number generation.
- Journey animation.
- Final reward settlement.
- Damage-event application.
- Results-screen breakdown.
- Optimal-route calculation.
- Route recommendation.
- Procedural job generation.

## Dependencies

- Epic 1 – The Grid.
- Canonical gameplay rules for card timing, risk and reward inputs.
- Job configuration containing Target Time, Deadline and economy values.

## User Stories

### Understand route timing

As a player, I want to see an estimated arrival time so that I can judge whether a route is likely to meet the target and deadline.

### Compare delay exposure

As a player, I want to understand how exposed my route is to delays so that I can compare predictable and risky options.

### Compare damage risk

As a player, I want damage risk shown separately from delay exposure so that I can make an informed trade-off.

### Preview the best possible payout

As a player, I want to see the maximum reward available for my route so that I can decide whether the risk is worthwhile.

## Acceptance Criteria

- Estimated arrival updates when a card is added or removed.
- Target Time and Deadline display as distinct values.
- Delay exposure is shown as Low, Medium or High.
- Damage risk is shown as Low, Medium or High.
- Delay exposure and damage risk can differ for the same route.
- Maximum achievable reward updates when the route changes.
- No expected payout is displayed.
- No route is ranked, recommended or marked as optimal.
- Planning calculations are independent of SwiftUI views.
- The same route and job configuration always produce the same planning summary.

## Technical Notes

Create a route-analysis layer that accepts:

- ordered route cards;
- job timing configuration;
- economy configuration;
- card-rule definitions.

Return a presentation-neutral planning result containing all derived values.

Keep calculation policies injectable or centrally configured so balancing changes do not require view changes.

## Definition of Done

- All acceptance criteria are met.
- Unit tests cover estimated arrival, exposure classifications and maximum reward.
- Boundary tests cover classification thresholds.
- Tests confirm Target Time and Deadline are treated independently.
- UI tests verify live updates after route edits.
- Accessibility labels describe each planning value.

## References

- [Product Requirements Document](../PRD.md)
- [Gameplay Rules](../Gameplay-Rules.md)
- [Decision Log](../Decision-Log.md)
- [Epic 1 – The Grid](Epic-1-The-Grid.md)
