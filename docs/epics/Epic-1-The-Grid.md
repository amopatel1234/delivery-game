# Epic 1 – The Grid

## Goal

Build the core game board and route planning experience that allows the player to inspect the entire delivery map, construct a valid route from the depot to the destination, and prepare the simulation.

This epic establishes the foundation that every subsequent gameplay system depends upon.

## Scope

This epic includes:

- 5×5 grid presentation.
- Grid and card models.
- Depot and destination placement.
- Route construction.
- Orthogonal adjacency validation.
- Duplicate-card prevention.
- Repeated Undo support.
- Route preview.
- Confirm Route flow.
- Planning-state presentation.

Simulation, timing, hazards and rewards are out of scope.

## Player Experience

When a job starts, the player immediately sees:

- the complete grid;
- every card;
- the depot;
- the destination.

The player builds a route one card at a time until reaching the destination. No time passes and no card effects resolve during planning.

## Functional Requirements

### Grid

- Present a fixed 5×5 grid.
- Place the depot at the top-left position.
- Place the destination at the bottom-right position.
- Show all cards before planning begins.

### Route Building

- Select the depot automatically when planning begins.
- Add a card only when it is orthogonally adjacent to the current route endpoint.
- Prevent diagonal movement.
- Prevent a card from being added more than once.
- Preserve route order.

### Undo

- Allow repeated Undo back to the depot.
- Remove only the most recently selected card.
- Keep the depot selected as the minimum route state.

### Route Validation

- Treat the route as complete only when the destination is the current endpoint.
- Keep Confirm Route disabled until the route is complete.
- Lock route editing after confirmation.

### Planning Information Integration

Provide presentation points for:

- estimated arrival;
- target time;
- deadline;
- delay exposure;
- damage risk;
- maximum reward.

The calculations behind these values belong to later epics.

## Out of Scope

- Card-effect resolution.
- Time simulation.
- Damage.
- Reward calculation.
- Economy.
- Deck generation.
- Seed selection.
- Tutorial content.
- Final animation and audio polish.

## Dependencies

None.

## User Stories

### Inspect the board

As a player, I want to see the complete delivery map so that I can plan before committing.

### Construct a route

As a player, I want to build a connected route so that I can choose how to reach the destination.

### Undo route choices

As a player, I want to undo my most recent choice so that I can experiment safely.

### Confirm a complete route

As a player, I want confirmation to become available only when the destination is reached so that I cannot start an invalid run.

## Acceptance Criteria

- A 5×5 grid displays correctly.
- Depot and destination occupy their fixed positions.
- All cards are visible.
- Route growth is limited to valid orthogonal moves.
- Duplicate visits are prevented.
- Undo works repeatedly back to the depot.
- Confirm Route remains disabled until the destination is the endpoint.
- Confirming the route locks further editing.
- Planning-information placeholders update when the route changes.
- SwiftUI views do not own route-validation logic.

## Technical Notes

Separate:

- grid model;
- card model;
- route model;
- planning state;
- SwiftUI rendering.

Use coordinate-based positions and constant-time orthogonal adjacency checks. Domain rules must remain outside SwiftUI views.

## Definition of Done

- All acceptance criteria are met.
- Unit tests cover adjacency, duplicate prevention, route completion and Undo.
- UI tests cover route creation, invalid moves, Undo and confirmation state.
- Accessibility identifiers exist for interactive grid elements and route controls.

## References

- [Product Requirements Document](../PRD.md)
- [Gameplay Rules](../Gameplay-Rules.md)
- [Decision Log](../Decision-Log.md)
