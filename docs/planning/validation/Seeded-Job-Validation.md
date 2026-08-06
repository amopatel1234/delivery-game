# Seeded Job Validation Record

Internal E6-S04 sign-off for the five authored MVP jobs before external TestFlight.

Source of truth for live values: `SeededJobCatalogue` / `SeededJobValidationRecord`.

## Accepted seeds and timing

| Job | ID | Seed | Target Time | Deadline | Design intent |
|---|---|---:|---:|---:|---|
| Direct but Risky | `direct_but_risky` | 1001 | 10 | 16 | Short route with Heavy Traffic exposure and a safer alternative. |
| Predictable Detour | `predictable_detour` | 2002 | 12 | 18 | Longer deterministic route competing with a shorter uncertain route. |
| Fast Lane Temptation | `fast_lane_temptation` | 3003 | 9 | 15 | Fast Lane meaningfully changes timing or reward potential. |
| Deadline Pressure | `deadline_pressure` | 4004 | 10 | 12 | Tight timing margin where route composition matters. |
| Close Decision | `close_decision` | 5005 | 11 | 17 | Two comparable routes with no obviously dominant option. |

Shared economy: MVP base 100 / early +5 / late −20 / damage −20 / clamp 0.

## Automated checks

`SeededJobValidationTests` verifies:

- catalogue alignment with this record;
- board structural validity and load determinism;
- each job has multiple complete routes with distinct lengths;
- sampled routes confirm through `RouteBuilder` + `RouteValidator`;
- required card types for design intent are present;
- Direct but Risky hazard-profile diversity;
- Fast Lane Temptation routes with and without Fast Lane;
- Deadline Pressure timing margin (`deadline - target == 2`).

## Internal playtest checklist

- [ ] Complete Jobs 1–5 sequentially on a supported simulator/device.
- [ ] Try Undo repeatedly and at least one longer practical route per job.
- [ ] Confirm completed and failed outcomes (early / on-target / late / missed deadline).
- [ ] Confirm onboarding clean state and completed state.
- [ ] Confirm replay selection after Job 5.
- [ ] Spot-check VoiceOver labels, Dynamic Type, and Reduce Motion.
- [ ] Confirm Release builds hide Reset Onboarding.

## Sign-off

Validation status: **accepted for external TestFlight** when catalogue regression tests and `SeededJobValidationTests` pass on `main`.
