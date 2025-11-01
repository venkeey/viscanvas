## Automated Testing Guide

This document explains every way you can automatically test the current app, mapped to the folders under `test/`, and shows exactly how to run each type of test locally and in CI.

### Prerequisites
- Flutter SDK installed and on PATH
- At least one target device available when running device tests:
  - Desktop: `windows`/`macos`/`linux`
  - Mobile emulator/simulator or a physical device
  - Web: Chrome

Check devices:

```bash
flutter doctor
flutter devices
```

### Test layout at a glance
- `test/unit/` — fast, pure Dart logic tests
- `test/widget/` — widget tests (render tree, interactions with test harness)
- `test/integration/` — integration tests using `integration_test`
- `test/e2e/` — full end-to-end flows (can be driven by `integration_test`, Patrol, or Maestro)
- `test/visual/` — visual and golden/pixel-diff style tests
- `test/performance/` — performance and frame timing checks
- `test/security/` — static checks and runtime guards
- `test/accessibility/` — semantics and a11y assertions
- `test/helpers/` — shared fixtures, fakes, utilities


## 1) Unit tests (`test/unit/`)
Purpose: Validate pure Dart logic, models, and services without Flutter bindings.

Run all unit tests:
```bash
flutter test test/unit
```

Run a single file:
```bash
flutter test test/unit/path_to_test.dart
```

With coverage (creates `coverage/lcov.info`):
```bash
flutter test --coverage test/unit
```


## 2) Widget tests (`test/widget/`)
Purpose: Verify widget behavior with the Flutter test framework, including layout, gestures, and semantics.

Run all widget tests:
```bash
flutter test test/widget
```

Tips:
- Use `pumpWidget`, `pump`, `pumpAndSettle` to advance frames.
- Prefer deterministic inputs; mock services via `test/helpers`.


## 3) Integration tests (`test/integration/`)
Purpose: Exercise the app on a real or simulated device with `integration_test`.

Run on desktop (Windows example):
```bash
flutter test integration_test -d windows
```

Run on Chrome (Web):
```bash
flutter test integration_test -d chrome
```

Run on Android emulator / iOS simulator (choose your device id):
```bash
flutter test integration_test -d <device_id>
```

Notes:
- Ensure an appropriate device is listed in `flutter devices`.
- Keep tests idempotent; reset state between tests.


## 4) End-to-End tests (`test/e2e/`)
Purpose: Validate full user journeys. You can drive these with:

- `integration_test` (already covered above)
- Patrol (configured via `patrol.yaml` in the repo root)
- Maestro flows (YAML specs under `maestro/`)

Patrol (run non-interactively):
```bash
flutter pub run patrol test --no-pub --target integration_test --device <device_id>
```

Maestro (install Maestro CLI first):
```bash
maestro test maestro
```

Choose one framework consistently per suite to keep reports clear.


## 5) Visual tests (`test/visual/`)
Purpose: Detect visual regressions via golden or pixel-diff testing.

Golden tests (baseline images committed next to tests):
```bash
flutter test test/visual
```

Common patterns:
- Use `matchesGoldenFile('goldens/widget_name.png')`.
- When intentional UI changes occur, update goldens locally, review diffs, then commit.

Pixel testing via integration tests:
- Capture screenshots at key states and compare to master images.
- Store diffs and failures under a known directory (e.g., `test/visual/failures/`).


## 6) Performance tests (`test/performance/`)
Purpose: Keep frame times, memory, and startup within budgets.

Suggested flows:
- Profile mode run to capture frame timings:
```bash
flutter run --profile -d <device_id>
```
- Integration test that records `FrameTiming` and asserts thresholds:
```bash
flutter test integration_test -d <device_id>
```

Guidelines:
- Warm up before measuring.
- Fail the test if average frame build/raster time exceeds your budget.


## 7) Security tests (`test/security/`)
Purpose: Static checks and basic runtime validations.

Static analysis:
```bash
flutter analyze
```

Runtime guards in tests:
- Verify sensitive data is not logged.
- Ensure inputs are validated and exceptions are handled.


## 8) Accessibility tests (`test/accessibility/`)
Purpose: Enforce semantics, labels, and navigability.

Widget-level semantics checks:
```bash
flutter test test/accessibility
```

Integration-level checks:
- Navigate core screens and assert important nodes are reachable and labeled.


## 9) Test helpers (`test/helpers/`)
Centralize:
- Fakes/mocks and test doubles
- Common widget harnesses and test wrappers
- Sample fixtures and builders for models


## 10) Running everything
Run all tests (unit + widget + any visual goldens):
```bash
flutter test
```

Then run device-driven suites (choose devices as needed):
```bash
flutter test integration_test -d windows
flutter test integration_test -d chrome
# or mobile device id
flutter test integration_test -d <device_id>
```

Optionally run E2E via Patrol or Maestro:
```bash
flutter pub run patrol test --no-pub --target integration_test -d <device_id>
maestro test maestro
```

Collect coverage for Dart-only tests:
```bash
flutter test --coverage
```


## 11) CI recommendations
- Cache Flutter SDK and pub dependencies
- Jobs:
  - Lint: `flutter analyze`
  - Unit+Widget: `flutter test --coverage`
  - Integration (matrix over platforms/devices available to your runner)
  - Optional: Visual/golden diffs as artifacts
  - Optional: Publish coverage to your provider


## 12) Troubleshooting
- No devices listed: create/start an emulator or attach a device; for desktop ensure the platform is enabled.
- Golden diffs failing after intended UI change: update baselines deliberately; review diffs before committing.
- Flaky integration tests: add explicit waits for network/idles, reduce animation durations under test, and stabilize data fixtures.


## 13) Quick command reference
- Unit only: `flutter test test/unit`
- Widget only: `flutter test test/widget`
- Visual/goldens: `flutter test test/visual`
- All host tests: `flutter test`
- Integration (choose device): `flutter test integration_test -d <device_id>`
- Patrol E2E: `flutter pub run patrol test --no-pub --target integration_test -d <device_id>`
- Maestro flows: `maestro test maestro`
- Coverage: `flutter test --coverage`











