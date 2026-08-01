# Gameplay Rules

## Core Loop
1. Load seeded job.
2. Inspect fully revealed 5x5 grid.
3. Plan route.
4. Confirm route.
5. Simulate automatically.
6. Calculate reward.
7. Show results.

## Grid
- Fixed 5x5.
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
### Clear Road
Normal travel.

### Light Traffic
Applies a fixed time delay.

### Heavy Traffic
- 50% chance of a delay.
- If delayed, 15% chance of a damage event.

### Roadworks
Applies a fixed time delay.

### Fast Lane
- Zero travel time.
- Never delayed.
- Never damaged.

## Timing
Each job defines:
- Target Time.
- Deadline.

Target Time awards early bonuses.
Deadline applies lateness penalties.

## Damage
- Damage is run-scoped only.
- Damage does not persist between jobs.

## Reward
The UI displays the maximum achievable reward for the planned route.
Final reward is derived from:
- Base reward.
- Early bonus.
- Late penalties.
- Damage penalties.

## Jobs
- Five deterministic seeded jobs for MVP.
- Played sequentially.
- After Job 5 the player may replay any seeded job.
- Random jobs are introduced only after seeded validation is complete.
