# TestFlight Release (E6-S05)

Release readiness for **Couriers Gambit** (`com.amishpatel.couriesgambit.game`) before external playtesting.

## Versioning

| Field | Source | MVP value |
|---|---|---|
| Marketing version | Xcode `MARKETING_VERSION` | `1.0` |
| Build number | Fastlane `latest_testflight_build_number` + 1 | Ascends per upload for `1.0` |
| Bundle ID | App target | `com.amishpatel.couriesgambit.game` |
| Team ID | Fastlane / Xcode | `24CTGGM78R` |

No GitHub Releases. Build numbers come from TestFlight only.

## Signing & archive

| Item | Value |
|---|---|
| Certificate | Apple Distribution `.p12` (`DISTRIBUTION_CERTIFICATE` secret) |
| Profile | **Couriers Gambit App Store Profile** (readonly via Fastlane) |
| Export method | `app-store` |
| CI workflow | `.github/workflows/merged.yml` → `bundle exec fastlane deploy` |
| Manual trigger | Actions → **Merged** → `workflow_dispatch` |

Repository secrets required: `DISTRIBUTION_CERTIFICATE`, `DISTRIBUTION_PASSWORD`, `KEY_VALUE`.

## App Store Connect / TestFlight groups

| Group | How builds arrive |
|---|---|
| **Internal** | Enable **Automatic distribution** in ASC (API cannot assign internal groups) |
| **External** | Fastlane `distribute_external: true` + `groups: ["External"]` after processing |

First-time external distribution may require Beta App Review in App Store Connect.

## Release notes (What to Test)

Uploaded from [`fastlane/testing_notes.txt`](../../fastlane/testing_notes.txt) as the TestFlight changelog on every deploy.

## Tester instructions

See [`TestFlight-Tester-Instructions.md`](TestFlight-Tester-Instructions.md).

## Known limitations (intentional MVP scope)

- No App Store public release in this story.
- No persistent meta-progression or cloud saves (onboarding completion may persist locally).
- No random / procedural jobs — only the five seeded jobs.
- No star ratings, upgrades, repairs, or business management.
- No UI test target — CI uses unit tests only.
- Visuals are simple native SwiftUI (polish is intentional but not final art).
- DEBUG builds may show **Reset Onboarding**; Release builds hide it.
- Internal group assignment is ASC Automatic distribution only.

## Pre-upload checklist

- [ ] `SeededJobValidationTests` and unit tests green on `main`
- [ ] [`Seeded-Job-Validation.md`](Seeded-Job-Validation.md) accepted seeds/timings unchanged or intentionally retuned
- [ ] `fastlane/testing_notes.txt` updated for this build
- [ ] ASC **Internal** Automatic distribution enabled
- [ ] ASC **External** group named exactly `External` exists
- [ ] Merge to `main` (or run **Merged** workflow) and confirm ASC processing + External assignment

## Post-upload verification

- [ ] Build appears in TestFlight for Internal testers
- [ ] Build is available (or submitted) for the External group
- [ ] Changelog matches `testing_notes.txt`
- [ ] Smoke: Start Game → Job 1 planning loads on a device/simulator install
