# Epic 6 – Polish, Validation and TestFlight

## Goal

Turn the complete MVP gameplay loop into a stable, understandable and testable external TestFlight build, then use structured feedback from the five seeded jobs to validate whether route planning is intrinsically fun.

This epic focuses on usability, accessibility, reliability, presentation quality and evidence collection. It does not expand the product scope.

## Scope

This epic includes:

- First-run onboarding for the core loop.
- Final presentation polish for planning, execution and results.
- Tunable animation timing.
- Sound and haptic feedback where appropriate.
- Accessibility support.
- Seeded-job balancing and regression validation.
- Internal quality assurance.
- Analytics or lightweight feedback capture required for MVP validation.
- App configuration, signing and TestFlight distribution.
- External playtest instructions.
- Feedback review and balance iteration.

New gameplay systems are out of scope.

## Player Experience

A first-time player should be able to:

- understand the objective without external explanation;
- identify the depot and destination;
- build and undo a route;
- understand Target Time, Deadline, delay exposure, damage risk and maximum reward;
- confirm a route confidently;
- follow execution outcomes;
- understand the final payout;
- move through the five seeded jobs;
- replay a seeded job after completing the sequence.

The MVP should feel coherent and responsive even though it intentionally uses simple native visuals.

## Functional Requirements

### Onboarding

- Introduce the objective: plan a route that maximises reward.
- Explain orthogonal route construction.
- Explain Undo and route confirmation.
- Explain the distinction between Target Time and Deadline.
- Explain delay exposure and damage risk as separate concepts.
- Explain maximum achievable reward without implying expected payout.
- Introduce card meanings at the point they become relevant.
- Allow onboarding to be skipped or dismissed.
- Persist only lightweight onboarding-completion state.
- Allow onboarding to be reset in development and test builds.

### Visual Polish

- Give each card type a clear and consistent visual identity.
- Make depot, destination, selected route and current execution position visually distinct.
- Provide clear selected, available, invalid and locked interaction states.
- Ensure planning information remains readable on supported iPhone sizes.
- Keep layout stable as values update.
- Present completed and failed outcomes clearly.
- Use native shapes and SF Symbols where suitable.

### Motion

- Animate route selection and Undo without delaying input.
- Animate movement through the confirmed route.
- Make delay and damage events noticeable but not excessive.
- Use centrally configurable animation durations.
- Respect Reduce Motion by shortening, simplifying or removing nonessential animation.
- Keep domain execution independent from animation timing.

### Audio and Haptics

- Use restrained feedback for route selection, Undo, confirmation, delay, damage and result completion.
- Avoid using sound or haptics as the only way to communicate an outcome.
- Respect system settings and accessibility expectations.
- Keep feedback policies configurable and separate from domain logic.

### Accessibility

- Provide VoiceOver labels, values and hints for every interactive card and route control.
- Announce route changes, invalid selections, delay events, damage events and final outcomes.
- Do not rely on colour alone to distinguish card types or states.
- Support Dynamic Type for non-grid text.
- Maintain adequate contrast.
- Provide accessibility identifiers for automated UI tests.
- Preserve usability with Reduce Motion enabled.

### Seeded-Job Balancing

Validate each authored job against its intended scenario:

1. Direct but Risky.
2. Predictable Detour.
3. Fast Lane Temptation.
4. Deadline Pressure.
5. Close Decision.

For each job:

- verify at least one valid route exists;
- identify the meaningful route alternatives;
- verify no unintended obviously dominant route undermines the scenario;
- tune Target Time and Deadline;
- confirm the shared economy produces understandable trade-offs;
- record the accepted seed and timing values;
- rerun structural regression tests after changes.

Balancing changes must not silently change canonical mechanics.

### Internal Validation

Before external TestFlight:

- complete all five jobs on supported devices or simulators;
- test alternative routes, repeated Undo and maximum-length practical routes;
- test all card outcomes using deterministic random-number overrides;
- test onboarding from a clean state;
- test seeded-job progression and replay selection;
- test completed and failed outcomes;
- test VoiceOver, Dynamic Type and Reduce Motion;
- verify no run-scoped state leaks into the next job;
- verify release builds contain no unintended developer controls.

### MVP Feedback Capture

Collect enough structured evidence to answer the MVP question.

At minimum, capture or ask testers about:

- whether route construction was understood;
- whether Target Time and Deadline were understood;
- whether delay exposure and damage risk affected route choice;
- which route was chosen and why;
- whether alternatives felt meaningful;
- whether the result felt fair and understandable;
- whether the tester wanted to retry or compare another route;
- which seeded job felt strongest or weakest.

Feedback may be collected through an external form, lightweight in-app prompt or manual playtest notes. A full analytics platform is not required.

### TestFlight Distribution

- Configure the app identifier, version and build number.
- Configure signing and required App Store Connect metadata.
- Produce a Release build using the supported Xcode and iOS 26 SDK.
- Archive and upload successfully.
- Create an internal TestFlight group.
- Resolve internal validation issues before external distribution.
- Create an external tester group and submit the build for Beta App Review when required.
- Provide concise test instructions focused on the five seeded jobs.
- Record known limitations that are intentionally outside MVP scope.

### Validation Gate

The seeded MVP is considered validated only when feedback provides evidence that:

- players understand the core loop;
- players identify meaningful route alternatives;
- risk and timing information changes decisions;
- players can explain the consequences of their chosen route;
- outcomes feel attributable to planning and visible risk;
- players show interest in replaying or improving.

Random standalone jobs remain disabled until this gate is reviewed and accepted.

## Out of Scope

- Random standalone job mode.
- New card types.
- Vehicles, upgrades or repairs.
- Business management or progression.
- App Store launch marketing.
- Leaderboards or Game Center.
- Cloud save.
- iPad-specific redesign.
- Localisation beyond ensuring strings are localisation-ready.
- A production-scale analytics platform.

## Dependencies

- Epic 1 – The Grid.
- Epic 2 – Route Planning.
- Epic 3 – Execution and Hazard Resolution.
- Epic 4 – Economy and Outcome.
- Epic 5 – Deck and Seeded Job Generation.
- Final accepted seeds, Target Times and Deadlines.
- App Store Connect access and signing configuration.

## User Stories

### Learn the game

As a first-time player, I want concise guidance so that I can understand the route-planning loop without outside help.

### Follow the action

As a player, I want clear visual, audio and haptic feedback so that execution outcomes are easy to understand.

### Play accessibly

As a player using accessibility features, I want the full game loop to remain understandable and operable.

### Validate the MVP

As the product owner, I want structured playtest feedback from the five seeded jobs so that I can decide whether the core route-planning concept is worth expanding.

### Receive a test build

As an external tester, I want a stable TestFlight build with clear instructions so that I can focus on evaluating the gameplay.

## Acceptance Criteria

- A new player can complete the core loop using only in-app guidance.
- Onboarding explains route construction, timing, risk and maximum reward accurately.
- Onboarding can be skipped and does not repeatedly appear after completion.
- Every card type and route state is visually distinguishable without relying only on colour.
- Execution motion and feedback clearly communicate normal movement, delay and damage.
- Reduce Motion produces an appropriate alternative presentation.
- VoiceOver can identify cards, route state, planning values, execution outcomes and result actions.
- Dynamic Type does not hide essential non-grid information.
- All five seeded jobs satisfy their documented scenario intent after balancing.
- Accepted seed layouts are protected by regression tests.
- Internal validation covers all card outcomes and seeded-job progression.
- Release builds exclude unintended debugging controls.
- A Release archive uploads successfully to App Store Connect.
- Internal TestFlight installation and launch succeed.
- External tester instructions identify the validation goals and known limitations.
- Feedback is collected against the MVP success criteria.
- Random standalone jobs remain unavailable until the validation gate is accepted.

## Technical Notes

Keep presentation polish separate from domain behaviour. Animation, audio and haptic timing must not alter execution results or random-number consumption.

Use a lightweight feature or environment configuration for development-only controls, deterministic test overrides and onboarding reset. Ensure these controls are excluded or inaccessible in external Release builds.

Prefer automated regression coverage for deterministic systems and a concise manual release checklist for accessibility, App Store Connect and device-level validation.

## Definition of Done

- All acceptance criteria are met.
- Unit, integration and UI test suites pass in the Release-candidate configuration.
- The five accepted seeded jobs and timing values are documented and regression-tested.
- VoiceOver, Dynamic Type and Reduce Motion have been manually validated.
- No critical or high-severity defects remain open.
- A build is available to internal TestFlight testers.
- External TestFlight distribution is approved or ready for invitation.
- Test instructions and feedback questions are published.
- Initial playtest feedback has been reviewed against the MVP validation gate.
- Documentation is updated with any accepted balancing decisions.

## References

- [Product Requirements Document](../PRD.md)
- [Gameplay Rules](../Gameplay-Rules.md)
- [Decision Log](../Decision-Log.md)
- [Roadmap](../Roadmap.md)
- [Epic 1 – The Grid](Epic-1-The-Grid.md)
- [Epic 2 – Route Planning](Epic-2-Route-Planning.md)
- [Epic 3 – Execution and Hazard Resolution](Epic-3-Execution-and-Hazard-Resolution.md)
- [Epic 4 – Economy and Outcome](Epic-4-Economy-and-Outcome.md)
- [Epic 5 – Deck and Seeded Job Generation](Epic-5-Deck-and-Card-Generation.md)
