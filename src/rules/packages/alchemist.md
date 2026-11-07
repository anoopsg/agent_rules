---
trigger: auto
description: Alchemist package conventions for Flutter golden testing. Apply when using alchemist, writing declarative UI tests, or configuring GoldenTestGroup and GoldenTestScenario.
---

# Package: Alchemist (Golden Testing)

- **Test Wrapper:** Always use `goldenTest()` instead of `testWidgets()` to ensure platform-agnostic rendering and proper CI integration.
- **Grouping:** Use `GoldenTestGroup` to combine multiple states or themes of the same widget into a single test file, reducing image clutter.
- **Scenarios:** Define individual states (e.g., loading, success, error) inside a group using `GoldenTestScenario`.
- **Theme & Text Scale:** Set the theme through `AlchemistConfig(theme: ...)` (`goldenTest` has no `theme` parameter); without it, theme extensions such as app color tokens are missing. Set text scale with the `textScaleFactor` parameter instead of wrapping widgets in `MediaQuery`.
- **Configuration:** Use `AlchemistConfig` globally (in `flutter_test_config.dart`) to enforce `ciGoldensConfig` in CI environments to prevent OS-level text-rendering deviations.
- **Fonts & Typography:** `goldenTest()` loads app fonts itself; do not call `loadAppFonts()` (that is `golden_toolkit`, not Alchemist).
