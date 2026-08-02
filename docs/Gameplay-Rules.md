# Gameplay Rules

## Core Loop
1. Load seeded job.
2. Inspect fully revealed 5×5 grid.
3. Plan route.
4. Confirm route.
5. Simulate automatically.
6. Calculate reward.
7. Show results.

## Grid
- Fixed 5×5.
- Depot top-left.
- Destination bottom-right.
- Orthogonal movement only.
- All cards visible before planning.

## Planning
- No time passes while planning.
- Undo may be used repeatedly.
- Route must end at the destination before confirmation.
- Route cannot be edited after confirmation.

## Cards

Initial balancing values (may change through playtesting without changing product scope):

| Card | Base travel | Delay | Delay chance | Damage chance |
|---|---:|---:|---:|---:|
| Clear Road | 1 minute | — | — | — |
| Light Traffic | 1 minute | +1 minute | Always | — |
| Heavy Traffic | 1 minute | +2 minutes | 50% | 15% if delayed |
| Roadworks | 1 minute | +2 minutes | Always | — |
| Fast Lane | 0 minutes | — | — | — |

### Clear Road
Applies normal travel time. Never delayed. Never damaged.

### Light Traffic
Applies normal travel time and its fixed delay. Never damaged.

### Heavy Traffic
- Applies normal travel time.
- 50% chance of a delay.
- If delayed, 15% chance of a damage event.
- Overall per-card damage probability is 7.5%.

### Roadworks
Applies normal travel time and its fixed delay. Never damaged.

### Fast Lane
- Zero travel time.
- Never delayed.
- Never damaged.

## Planning Risk
Independent event probabilities are combined using:

`1 - product(1 - eventProbability)`

### Delay Exposure
- Low: below 25%.
- Medium: 25% to below 50%.
- High: 50% or above.

### Damage Risk
- Low: below 10%.
- Medium: 10% to below 25%.
- High: 25% or above.

Delay exposure and damage risk are calculated and presented separately.

## Timing and Outcome
Each job defines a Target Time and a Deadline.

- Before Target Time: completed with an early bonus.
- At Target Time: completed with no early bonus.
- After Target Time but before Deadline: completed with a lateness penalty.
- At or after Deadline: failed with zero payout.

## Damage
- Damage is run-scoped only.
- Damage does not persist between jobs.

## Reward
The UI displays the maximum achievable reward for the planned route.

Final reward is derived from:
- Base reward.
- Early bonus.
- Lateness penalty.
- Damage penalties.

Final reward cannot fall below zero.

## Jobs
- Five deterministic seeded jobs for MVP.
- Played sequentially.
- After Job 5 the player may replay any seeded job.
- Random jobs are introduced only after seeded validation is complete.
