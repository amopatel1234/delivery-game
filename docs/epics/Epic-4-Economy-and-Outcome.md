# Epic 4 – Economy and Outcome

## Goal

Calculate the completed or failed result from the execution event history, settle the run's currency reward, and present an itemised explanation of the outcome.

This epic turns the resolved journey into a result the player can understand and compare against other route choices.

## Scope

This epic includes:

- Outcome calculation from completed execution data.
- Completed and failed states.
- Base reward.
- Early-delivery bonus.
- Lateness penalty.
- Damage-event penalty.
- Final reward clamping and settlement.
- Itemised result breakdown.
- Results-screen presentation.
- Sequential seeded-job progression.
- Seeded-job selection after Job 5.
- Run-state reset between jobs.

Persistent progression and the broader business economy are out of scope.

## Player Experience

When execution ends, the player sees a clear explanation of:

- whether the job was completed or failed;
- the actual delivery time;
- the Target Time;
- the Deadline;
- the number of damage events;
- each bonus and penalty;
- the final currency earned.

The result must be traceable to the route execution. The player should never need to infer why the payout changed.

## Functional Requirements

### Outcome Input

Calculate the result from immutable execution data containing at least:

- active job configuration;
- final elapsed time;
- damage-event count;
- ordered resolution-event history;
- route completion state.

Do not recalculate hazards or consume additional random values during settlement.

### Timing Outcomes

Apply the canonical timing rules exactly:

- **Before Target Time:** completed with an early bonus.
- **At Target Time:** completed with no early bonus and no lateness penalty.
- **After Target Time but before Deadline:** completed with a lateness penalty.
- **At or after Deadline:** failed with zero payout.

Target Time and Deadline are distinct boundaries and must be tested independently.

### Completed and Failed States

- Mark a run as completed only when the destination is resolved before the Deadline.
- Mark a run as failed when the actual time is at or after the Deadline, or when the delivery otherwise cannot be completed according to the canonical gameplay rules.
- Keep completed or failed status separate from payout quality.
- A failed run always settles to zero payout.
- Do not use star ratings.

### Reward Calculation

Use the active job's economy configuration.

Initial shared MVP values are:

- Base reward: 100 coins.
- Early bonus: 5 coins per whole minute early.
- Late penalty: 20 coins per whole minute late.
- Damage penalty: 20 coins per damage event.

Calculate components independently:

- For a completed run, start from the base reward.
- When actual time is before Target Time, calculate early minutes as `Target Time - actual time` and apply the early bonus.
- When actual time equals Target Time, apply neither an early bonus nor a lateness penalty.
- When actual time is after Target Time but before Deadline, calculate late minutes as `actual time - Target Time` and apply the lateness penalty.
- Apply the damage penalty once per recorded damage event for completed runs.
- Do not derive damage penalties from a persistent vehicle-condition value.
- For failed runs, set final reward to zero regardless of base reward, bonuses, lateness penalties or damage penalties.
- Clamp every completed-run reward to a minimum of zero.

Balancing values must be centrally configurable rather than embedded in views.

### Itemised Breakdown

Produce a presentation-neutral result model containing:

- outcome status;
- base reward;
- early minutes and early bonus;
- late minutes and lateness penalty;
- damage-event count and damage penalty;
- final reward;
- actual time;
- Target Time;
- Deadline.

Use zero-valued components rather than hiding calculation state from the domain model. Presentation may omit rows that do not apply.

For failed runs, the model must still preserve timing and damage information for explanation while final reward remains zero.

### Results Screen

Present:

- a clear completed or failed heading;
- final reward as the primary result;
- actual time, Target Time and Deadline;
- damage-event count;
- an itemised payout breakdown;
- a route or event recap link or section;
- the next available action.

The results screen must remain stable until the player chooses to continue or replay.

### Seeded-Job Progression

- Begin with Job 1 for a fresh MVP test session unless a test override is active.
- Advance sequentially from Job 1 through Job 5.
- After completing Job 5, present a seeded-job selection screen.
- Allow any of the five seeded jobs to be replayed from that screen.
- Starting or replaying a job resets run-scoped time, damage, route and resolution state.
- Do not silently generate a random job.

### Economy Consistency

- All five initial seeded jobs share one economy configuration.
- Seed, Target Time and Deadline may vary per job.
- The same outcome input must always produce the same payout breakdown.
- Planning maximum reward and final settlement must use the same underlying economy policies.

## Out of Scope

- Star ratings.
- Persistent currency spending.
- Vehicles, upgrades or repairs.
- Business management.
- Contracts or cargo systems.
- Reputation or unlock progression.
- Procedural job generation.
- Cloud persistence.
- Leaderboards.
- Final visual, audio and haptic polish.

## Dependencies

- Epic 1 – The Grid.
- Epic 2 – Route Planning.
- Epic 3 – Execution and Hazard Resolution.
- Epic 5 – Deck and Seeded Job Generation.
- Job configuration containing timing and economy values.
- Canonical reward and outcome rules.

## User Stories

### Understand the result

As a player, I want to see whether the job succeeded and how the payout was calculated so that the outcome feels fair.

### Compare performance against job timing

As a player, I want to compare my actual time with the Target Time and Deadline so that I understand bonuses, penalties and failure.

### Continue through the seeded jobs

As a tester, I want jobs to advance in a fixed order so that I experience the intended validation sequence.

### Replay a scenario

As a tester, I want to select any seeded job after completing the sequence so that I can compare alternative routes.

## Acceptance Criteria

- Settlement uses the execution result without consuming random values.
- A run completed before Target Time receives an early bonus.
- A run completed exactly at Target Time receives neither an early bonus nor a lateness penalty.
- A run completed after Target Time but before Deadline receives a lateness penalty.
- A run finishing exactly at Deadline fails.
- A run finishing after Deadline fails.
- Every failed run settles to zero payout.
- Every completed-run reward is clamped to a minimum of zero.
- Base reward, early bonus, lateness penalty and damage penalty are calculated separately.
- Damage penalty uses the recorded damage-event count.
- The result contains no star rating.
- The results screen shows actual time, Target Time and Deadline.
- The results screen shows an itemised reward breakdown.
- The displayed final reward matches the domain settlement result.
- The same input produces the same payout.
- Jobs advance sequentially from Job 1 through Job 5.
- Completing Job 5 exposes seeded-job selection.
- Replaying or starting a job clears all run-scoped state.
- No random job is created by the MVP progression flow.
- SwiftUI views contain no payout or outcome-calculation logic.

## Technical Notes

Create a pure settlement service that accepts an immutable execution result and job configuration, then returns a presentation-neutral outcome model.

Share economy policies with the planning analysis layer so maximum-reward previews cannot drift from final settlement.

Model seeded-job navigation separately from run execution. A job-session coordinator or equivalent state owner may manage sequential progression and replay selection without introducing persistent meta-progression.

## Definition of Done

- All acceptance criteria are met.
- Unit tests cover completed and failed outcomes.
- Unit tests cover early, exactly on target, late and damaged deliveries.
- Boundary tests cover one unit before Target Time, exactly at Target Time, one unit after Target Time, one unit before Deadline, exactly at Deadline and after Deadline.
- Tests cover multiple damage events and reward clamping.
- Tests confirm every failed run pays zero.
- Tests confirm settlement consumes no random values.
- Tests confirm planning and settlement share economy rules.
- UI tests cover result breakdown, sequential progression and seeded-job replay selection.
- Accessibility labels communicate outcome, time comparison and payout components.

## References

- [Product Requirements Document](../PRD.md)
- [Gameplay Rules](../Gameplay-Rules.md)
- [Decision Log](../Decision-Log.md)
- [Epic 1 – The Grid](Epic-1-The-Grid.md)
- [Epic 2 – Route Planning](Epic-2-Route-Planning.md)
- [Epic 3 – Execution and Hazard Resolution](Epic-3-Hazard-System.md)
- [Epic 5 – Deck and Seeded Job Generation](Epic-5-Deck-and-Card-Generation.md)
