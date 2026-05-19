---
name: golden-sandbox
description: >-
  Run sandboxed golden tests across a device and theme matrix after any
  UI change, classify diffs, fix regressions, and gate task completion
  on a clean run. Use when adding or modifying a screen, page, widget,
  layout, or theme token.
---
# Golden Sandbox Skill

This skill defines the sandboxed golden-testing workflow used to keep
UI work from regressing across device sizes, themes, and text scales.
It is mandatory after any change to a widget, layout, theme token, or
responsive behavior. The goal: every device/theme cell in the matrix
is green before the agent reports the task complete.

The "sandbox" is Flutter's in-memory test harness (`flutter_test`) plus
[`alchemist`](https://pub.dev/packages/alchemist) for ergonomic
multi-scenario rendering. No emulators, no devices.

## 1. When to Apply

Run the loop in section 5 before reporting the task complete whenever
you have:
- Added or modified a screen, page, or composite widget.
- Changed layout (paddings, alignments, flex factors, constraints).
- Edited theme tokens (colors, typography, spacing, radii).
- Touched responsive logic (breakpoints, web vs. mobile branching).
- Modified an asset that the UI depends on (icon, illustration).
- Updated a dependency that affects rendering (Material/Cupertino,
  text shaping, image decoding).

### 1.1 Drift Cases (Still Required)

These look small and routinely get skipped. They still require the loop:
- **Padding/margin tweak by N pixels.** Looks trivial; can shift entire
  layout on small phones or large text scales.
- **Single hex color change.** Often hides theme-token violations.
- **Refactor "with no visual change".** Stateless → Stateful, or
  splitting a widget into private classes — your assertion of "no
  visual change" is exactly what goldens verify.
- **Text label rewording.** Different string length → different wrap
  point → different layout in narrow cells.
- **Replacing a widget with a "structurally identical" one.** Material
  vs. Cupertino, `Container` vs. `DecoratedBox`, etc. — tiny pixel
  diffs are common.
- **Dependency bump that touches rendering.** Treat as a UI change.

If you are tempted to skip because the change "obviously can't affect
rendering", that is the moment to run the loop and prove it.

### 1.2 Genuine Skip Cases (Rare)

Goldens may be skipped only when ALL of these are true:
- No widget, view, layout, theme token, or asset file was modified.
- No dependency that affects rendering changed.
- The change is provably non-visual (pure logic, comments, doc edits,
  test-only changes outside `test/goldens/`).

If skipping, the turn summary MUST state the reason in the disclosure
format from section 5.6. Silent skip is a rule violation.

## 2. Sandbox Setup

### 2.1 Add the dependency
Add `alchemist` to `dev_dependencies` in `pubspec.yaml`:
```yaml
dev_dependencies:
  alchemist: ^0.11.0  # use latest stable from pub.dev
  flutter_test:
    sdk: flutter
```

> Swap-out: if the project already uses `golden_toolkit`, use
> `multiScreenGolden()` with the matrix in section 3. If using vanilla
> `flutter_test`, write one `testWidgets` per matrix cell calling
> `matchesGoldenFile`. The matrix and the loop in section 5 stay the
> same; only the API differs.

### 2.2 Pin determinism
Create `test/flutter_test_config.dart` so every golden run uses the
same locale, text scale, time, and shadow rendering:

```dart
import 'dart:async';
import 'package:alchemist/alchemist.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(
        renderShadows: true,
      ),
      ciGoldensConfig: CiGoldensConfig(
        renderShadows: true,
      ),
    ),
    run: testMain,
  );
}
```

### 2.3 Folder layout
Mirror source paths under `test/goldens/`:
```text
lib/features/login/login_view.dart
test/goldens/features/login/login_view_golden_test.dart
test/goldens/features/login/goldens/                  # baseline images
test/goldens/features/login/failures/                 # diff output (gitignored)
```

Add `test/**/failures/` to `.gitignore`.

## 3. Device & Theme Matrix

Every UI golden test must cover this matrix unless explicitly justified
in the test file's doc comment:

| Cell | Size | Theme | Text scale |
| :--- | :--- | :--- | :--- |
| phone-sm-light | 375x667 | light | 1.0 |
| phone-sm-light-a11y | 375x667 | light | 1.5 |
| phone-lg-dark | 414x896 | dark | 1.0 |
| tablet-light | 768x1024 | light | 1.0 |
| tablet-dark | 768x1024 | dark | 1.0 |
| desktop-light | 1280x800 | light | 1.0 |
| desktop-dark | 1280x800 | dark | 1.0 |

Define the matrix once as a `const` list and reuse it in every test.

## 4. Writing a Golden Test

```dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _matrix = <({String name, Size size, Brightness brightness, double scale})>[
  (name: 'phone-sm-light',       size: Size(375, 667),  brightness: Brightness.light, scale: 1.0),
  (name: 'phone-sm-light-a11y',  size: Size(375, 667),  brightness: Brightness.light, scale: 1.5),
  (name: 'phone-lg-dark',        size: Size(414, 896),  brightness: Brightness.dark,  scale: 1.0),
  (name: 'tablet-light',         size: Size(768, 1024), brightness: Brightness.light, scale: 1.0),
  (name: 'tablet-dark',          size: Size(768, 1024), brightness: Brightness.dark,  scale: 1.0),
  (name: 'desktop-light',        size: Size(1280, 800), brightness: Brightness.light, scale: 1.0),
  (name: 'desktop-dark',         size: Size(1280, 800), brightness: Brightness.dark,  scale: 1.0),
];

void main() {
  goldenTest(
    'LoginView matrix',
    fileName: 'login_view',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        for (final cell in _matrix)
          GoldenTestScenario(
            name: cell.name,
            child: MediaQuery(
              data: MediaQueryData(
                size: cell.size,
                textScaler: TextScaler.linear(cell.scale),
              ),
              child: Theme(
                data: ThemeData(brightness: cell.brightness),
                child: SizedBox.fromSize(
                  size: cell.size,
                  child: const LoginView(),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
```

Tag the test so it can be selected: add `@Tags(['golden'])` at the top
of the file, or rely on the `_golden_test.dart` filename suffix if the
project filters by glob.

## 5. The Loop (Gating Workflow)

This is the contract that blocks task completion. Run it in order
after every UI edit:

1. **Run goldens.** Use the project's golden command if defined (e.g.
   `melos run test:goldens`); otherwise:
   ```bash
   flutter test --tags golden
   ```
2. **On failure, read the diff.** Open the failure image at
   `test/goldens/.../failures/<scenario>.png`. The image shows expected
   vs. actual side by side.
3. **Classify the diff:**
   - **Regression** - the change broke something unrelated (overflow,
     wrong color, clipped text, missing widget). Go to step 4a.
   - **Intentional** - the change is what the spec asked for and the
     baseline is now stale. Go to step 4b.
4. **Resolve:**
   - **4a. Regression** - fix the widget code. Do not touch goldens.
     Re-run from step 1.
   - **4b. Intentional** - regenerate goldens for that test only:
     ```bash
     flutter test path/to/login_view_golden_test.dart --update-goldens
     ```
     Never run `--update-goldens` repo-wide; that hides regressions in
     unrelated tests.
5. **Re-run** from step 1. Loop until every cell is green.
6. **Disclose in the turn summary.** Use exactly one of these formats:
   - `goldens: <N> green` — all cells passed, no regeneration.
   - `goldens: <N> green, <M> regenerated (<reason>)` — list each
     regenerated test by name and why (e.g. "spec change: new disabled
     state"). Never collapse multiple unrelated regenerations into one
     line.
   - `goldens: skipped because <reason>` — only allowed if the change
     meets section 1.2. State which file was changed and why it cannot
     affect rendering.
7. **Only after disclosure** report the task complete.

## 6. Common Failure Modes & Fixes

| Symptom | Likely cause | Fix |
| :--- | :--- | :--- |
| `RenderFlex overflowed` in failure log | Hard-coded width/height collides with small phone or large text scale | Wrap in `Flexible`, `Expanded`, or `FittedBox`; use intrinsic sizing |
| Text clipped at scale 1.5 | Fixed-height container around `Text` | Remove the height cap; let the text drive layout |
| Color drift between runs | Hard-coded hex instead of theme token | Use `Theme.of(context).colorScheme.*` or the project's design-token accessor |
| Locale-sensitive string differs | Default locale leaked into the test | Force a locale in `MaterialApp(locale: Locale('en'))` inside the scenario |
| Animation frame jitter | Implicit animation in flight when snapshot taken | Wrap in `Animate`-disabled scope or `pump`/`pumpAndSettle` before capture |
| Asset missing in CI | Asset not declared in `pubspec.yaml` | Add to `flutter.assets`; rerun `pub get` |
| Shadows differ on macOS vs. Linux | Platform-specific rasterization | Use `ciGoldensConfig` separate from `platformGoldensConfig`; commit only the CI baseline |

## 7. CI Integration

CI is the only enforcement gate that is not a heuristic. Even if the
agent skips the loop, CI will catch the diff and fail the PR.

### 7.1 Principles
- Run goldens on every PR using the same Flutter version as local
  development (pin in `.fvmrc` or workflow).
- Fail the PR on any diff. Do not auto-update goldens in CI.
- Upload `test/**/failures/` as a workflow artifact so the agent can
  fetch the diff images on the next iteration without re-running locally.
- Cache `~/.pub-cache` and the iOS/Android toolchains; goldens
  themselves should not be cached so the matrix runs fresh.

### 7.2 Starter GitHub Actions Workflow

Drop this in `.github/workflows/goldens.yml`. Adjust the Flutter
version and tag/path filter to match the project:

```yaml
name: Goldens

on:
  pull_request:
  push:
    branches: [main]

jobs:
  goldens:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x' # pin to project's version
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run golden tests
        run: flutter test --tags golden

      - name: Upload failures on diff
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: golden-failures
          path: |
            test/**/failures/
            **/failures/*.png
          if-no-files-found: ignore
          retention-days: 7
```

For monorepos using melos, replace the test step with the project's
defined task (e.g. `melos run test:goldens`).

## 8. Pre-Completion Self-Check

Before producing the final response or marking the task done, answer:

1. Did I run goldens for every widget I modified, directly or
   transitively (parent widgets that compose mine)?
2. Are all device/theme/scale cells green?
3. If I regenerated baselines, did I commit the new `.png` files
   alongside the code change?
4. Does my turn summary contain the section 5.6 disclosure line, named
   per regenerated test, with reasons?
5. If I am claiming section 1.2 skip eligibility: did I list the file
   that changed and explain why it cannot affect rendering?

If any answer is "no" or "unknown", go back to section 5 step 1
before responding. This pairs with the [prevent-hallucination](../prevent-hallucination/SKILL.md)
skill: facts about UI behavior must be verified by goldens, not asserted.
