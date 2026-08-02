# Epic 1 – The Grid

## E1-S01 — Grid Domain Model

### Goal

Create the immutable domain model representing the delivery grid and its coordinates.

### Deliverable

Coordinate, position, grid cell and grid domain models.

### Scope

- Fixed 5×5 dimensions.
- Coordinate representation.
- Grid-cell lookup.
- Depot and destination representation.
- Board validation.

### Out of Scope

- SwiftUI rendering.
- Route construction.
- Planning analysis.

### Dependencies

- E5-S05.

### Acceptance Criteria

- Represents exactly 25 unique coordinates.
- Maps every coordinate to one card.
- Identifies depot and destination positions.
- Rejects duplicate, missing or out-of-bounds coordinates.
- Remains immutable after creation.
- Includes validation and lookup tests.

### References

- [Epic 1](../../epics/Epic-1-The-Grid.md)
- [Epic 5](../../epics/Epic-5-Deck-and-Card-Generation.md)

## E1-S02 — Grid Presentation

### Goal

Display a generated delivery board using SwiftUI.

### Deliverable

Responsive grid presentation.

### Scope

- 5×5 layout.
- Card-type presentation.
- Depot and destination distinction.
- Supported iPhone sizing.
- Basic accessibility identifiers.

### Out of Scope

- Route selection.
- Final visual polish.
- Planning calculations.

### Dependencies

- E1-S01.

### Acceptance Criteria

- Displays the entire board without scrolling on supported iPhones.
- Displays every card in the correct coordinate.
- Distinguishes depot and destination without relying only on colour.
- Adapts to supported screen widths.
- Exposes stable accessibility identifiers.
- Includes UI tests for board structure and fixed positions.

### References

- [Epic 1](../../epics/Epic-1-The-Grid.md)

## E1-S03 — Route Construction

### Goal

Allow the player to build an ordered route from the depot using valid orthogonal moves.

### Deliverable

Route builder domain capability integrated with the grid.

### Scope

- Automatic depot selection.
- Endpoint tracking.
- Orthogonal adjacency checks.
- Duplicate prevention.
- Ordered route state.
- Invalid-selection feedback state.

### Out of Scope

- Undo.
- Route confirmation.
- Planning calculations.

### Dependencies

- E1-S02.

### Acceptance Criteria

- Starts every route at the depot.
- Adds only cards orthogonally adjacent to the current endpoint.
- Rejects diagonal, non-adjacent and previously visited cards.
- Preserves selected route order.
- Keeps route-validation logic outside SwiftUI views.
- Includes adjacency, duplicate and invalid-move tests.

### References

- [Gameplay Rules](../../Gameplay-Rules.md)
- [Epic 1](../../epics/Epic-1-The-Grid.md)

## E1-S04 — Route Editing

### Goal

Allow the player to undo route choices safely before confirmation.

### Deliverable

Route undo capability.

### Scope

- Remove the most recent route card.
- Update endpoint and selected state.
- Repeated undo to the depot.

### Out of Scope

- Arbitrary middle-route editing.
- Route confirmation.
- Execution.

### Dependencies

- E1-S03.

### Acceptance Criteria

- Removes only the most recently selected card.
- Allows repeated undo until only the depot remains.
- Never removes the depot.
- Updates the active endpoint and grid selection immediately.
- Preserves a valid ordered route after every undo.
- Includes unit and UI tests for repeated undo.

### References

- [Gameplay Rules](../../Gameplay-Rules.md)
- [Epic 1](../../epics/Epic-1-The-Grid.md)

## E1-S05 — Route Validation

### Goal

Determine whether the current route is complete and eligible for confirmation.

### Deliverable

Route-completion validator.

### Scope

- Destination endpoint detection.
- Complete and incomplete states.
- Confirmation eligibility.

### Out of Scope

- Route confirmation transition.
- Timing and reward analysis.
- Execution.

### Dependencies

- E1-S03.

### Acceptance Criteria

- Marks a route complete only when the destination is its endpoint.
- Marks all other routes incomplete.
- Updates immediately after selection or undo.
- Produces a presentation-independent validation result.
- Includes boundary tests for depot-only, partial and destination-ending routes.

### References

- [Gameplay Rules](../../Gameplay-Rules.md)
- [Epic 1](../../epics/Epic-1-The-Grid.md)

## E1-S06 — Planning Screen Foundation

### Goal

Integrate the grid, route builder, undo control, confirmation state and planning-summary surface into one planning experience.

### Deliverable

Functional planning screen foundation.

### Scope

- Grid integration.
- Route-state presentation.
- Undo control.
- Confirmation control state.
- Presentation-neutral planning-summary input.

### Out of Scope

- Planning analysis calculations.
- Route confirmation transition.
- Final visual polish.

### Dependencies

- E1-S04.
- E1-S05.

### Acceptance Criteria

- Allows the player to build and edit a route from one screen.
- Shows route-selection state consistently.
- Enables confirmation only for a complete route.
- Provides a stable surface for all planning metrics.
- Keeps route and validation logic outside SwiftUI views.
- Includes UI tests covering route construction, undo and confirmation enablement.

### References

- [Epic 1](../../epics/Epic-1-The-Grid.md)
- [Epic 2](../../epics/Epic-2-Route-Planning.md)

---
