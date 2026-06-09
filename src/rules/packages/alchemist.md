---
trigger: auto
description: Alchemist package conventions for Flutter golden testing. Apply when using alchemist, writing declarative UI tests, or configuring GoldenTestGroup and GoldenTestScenario.
---

# Package: Alchemist (Golden Testing)

- **Test Wrapper:** Always use `goldenTest()` instead of `testWidgets()` to ensure platform-agnostic rendering and proper CI integration.
- **Grouping:** Use `GoldenTestGroup` to combine multiple states or themes of the same widget into a single test file, reducing image clutter.
- **Scenarios:** Define individual states (e.g., loading, success, error) inside a group using `GoldenTestScenario`.
- **Inline Overrides:** Override `theme` and `textScaleFactor` directly via `GoldenTestGroup` or `goldenTest` parameters, rather than wrapping widgets manually in `Theme` or `MediaQuery`.
- **Configuration:** Use `AlchemistConfig` globally (in `flutter_test_config.dart`) to enforce `ciGoldensConfig` in CI environments to prevent OS-level text-rendering deviations.
- **Fonts & Typography:** Ensure `loadAppFonts()` is called in the setup phase so text renders using correct fonts instead of the default Ahem font.
