# Epic 3 – Execution and Hazard Resolution

## Goal

Implement the execution phase that resolves a confirmed route from start to finish, applies each entered card's time and damage effects, and records a complete account of what happened.

This epic delivers the payoff to the planning phase: the player watches the consequences of the chosen route unfold without further intervention.

## Scope

This epic includes:

- Immutable confirmed-route input.
- Sequential route execution.
- Player-marker movement through the route.
- Card movement-time resolution.
- Delay resolution.
- Conditional Heavy Traffic damage resolution.
- Run-scoped damage-event tracking.
- Injected deterministic random-number generation.
- Structured resolution events for every entered card.
- Live execution-state presentation.
- Route recap data.

Reward settlement and final payout presentation belong to Epic 4.

## Player Experience

After confirming a route:

- route editing stops;
- the player marker moves through each entered card in order;
- time changes are shown as they occur;
- delay and damage outcomes are clearly communicated;
- execution continues automatically until the destination is resolved;
- the player can understand which cards produced each consequence.

Execution is deliberately non-interactive in the MVP.

## Functional Requirements

### Execution Lifecycle

- Accept an immutable confirmed route.
- Do not resolve the starting depot as a movement step.
- Resolve every subsequent route position exactly once and in order.
- Prevent duplicate or concurrent execution of the same route.
- Lock all planning controls for the duration of execution.
- Complete only after the destination card has resolved.

### Run State

Track run-scoped state containing at least:

- current route index;
- current grid position;
- elapsed delivery time;
- damage-event count;
- execution status;
- ordered resolution events.

Reset run state when a new job begins. Do not model persistent vehicle condition in the MVP.

### Card Resolution

Use the canonical rules for each entered card:

- **Clear Road:** apply normal movement time with no delay or damage.
- **Light Traffic:** apply normal movement time and its fixed delay; never apply damage.
- **Heavy Traffic:** apply normal movement time, roll for delay, and roll for damage only when the delay occurs.
- **Roadworks:** apply normal movement time and its guaranteed fixed delay; never apply damage.
- **Fast Lane:** apply zero travel time, no delay and no damage.

Card behaviour must be centrally configured and must not be implemented inside SwiftUI views.

### Random Resolution

- Use an injected random-number source.
- Use inclusive percentage rolls from 1 through 100.
- Keep roll order deterministic.
- Record relevant roll values in the resolution event.
- Allow tests to force success, failure and boundary outcomes.

For Heavy Traffic:

1. Roll for the 50% delay.
2. Only when delayed, roll for the 15% damage event.
3. Do not consume a damage roll when the delay does not occur.

### Resolution Events

Record one structured event for every entered card after the depot, including:

- route index;
- grid position;
- card type;
- base movement time;
- roll values where applicable;
- delay applied;
- whether damage occurred;
- elapsed time after resolution;
- cumulative damage-event count.

The event history is the authoritative source for live presentation, recap and later payout calculation.

### Execution Presentation

- Highlight the card currently being resolved.
- Move the player marker to each entered card.
- Use a tunable delay between visual steps.
- Update elapsed time and damage count after each resolution.
- Clearly distinguish normal movement, delay and damage.
- Prevent user interaction from changing the route or execution outcome.

### Route Recap

After execution, provide recap data that:

- includes every entered card after the depot exactly once;
- shows movement time, delay and damage separately;
- shows total elapsed time;
- shows total damage events;
- can be presented in a scrollable list for longer routes;
- remains available until the player proceeds.

Completed or failed status and payout belong to Epic 4, but must derive from this same event history.

## Out of Scope

- Route construction or editing.
- Planning estimates and exposure classifications.
- Final payout calculation.
- Completed or failed outcome calculation.
- Persistent vehicle condition.
- Repairs, breakdowns or maintenance.
- Player intervention during execution.
- Procedural job generation.
- Final animation, sound and haptic polish.

## Dependencies

- Epic 1 – The Grid.
- Epic 2 – Route Planning.
- Canonical card-rule definitions.
- Injectable deterministic random-number source.

## User Stories

### Watch the route execute

As a player, I want my confirmed route to resolve automatically so that I can see whether my plan succeeds.

### Understand each consequence

As a player, I want time, delay and damage outcomes shown as they occur so that the result never feels arbitrary.

### Review the journey

As a player, I want a recap of every entered card so that I can understand what affected the final result.

## Acceptance Criteria

- The depot costs no time and produces no resolution event.
- Every entered card after the depot resolves exactly once in route order.
- Execution cannot start twice for the same confirmed route.
- Planning controls remain locked during execution.
- Clear Road never delays or damages the player.
- Light Traffic applies its fixed delay and never damages the player.
- Heavy Traffic uses a 50% delay roll.
- Heavy Traffic damage is rolled only after a triggered delay.
- Heavy Traffic uses a 15% conditional damage roll.
- Roadworks always applies its fixed delay and never damages the player.
- Fast Lane consumes zero time and never delays or damages the player.
- Time and damage counts update after each card.
- Every entered card is represented once in the recap data.
- The same route, job and random-number sequence produce the same event history.
- SwiftUI views contain no hazard-resolution logic.

## Technical Notes

Model execution as a state machine with explicit idle, running and completed states.

The execution engine should accept:

- an immutable ordered route;
- card-rule definitions;
- an injected random-number source;
- initial run state.

It should produce a sequence of domain resolution events independent of animation timing. SwiftUI presentation may consume those events with a configurable visual cadence without changing the underlying outcome.

## Definition of Done

- All acceptance criteria are met.
- Unit tests cover every card type.
- Boundary tests cover percentage rolls at 1, threshold and threshold + 1.
- Tests prove Heavy Traffic does not consume a damage roll when its delay misses.
- Tests prove Fast Lane cannot produce delay or damage.
- Tests prove execution cannot run twice.
- Tests prove recorded event totals match final run state.
- UI tests cover route locking, visible progression and recap presentation.
- Accessibility announcements communicate delay and damage outcomes.

## References

- [Product Requirements Document](../PRD.md)
- [Gameplay Rules](../Gameplay-Rules.md)
- [Decision Log](../Decision-Log.md)
- [Epic 1 – The Grid](Epic-1-The-Grid.md)
- [Epic 2 – Route Planning](Epic-2-Route-Planning.md)
