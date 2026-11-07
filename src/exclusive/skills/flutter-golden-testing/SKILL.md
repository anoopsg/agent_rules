---
name: flutter-golden-testing
description: Creates and updates Alchemist golden (screenshot) tests for widgets. Use when adding a golden test, after changing a widget's appearance, or when goldens fail.
---

# Flutter Golden Testing Skill

This skill outlines the step-by-step process for implementing and updating golden tests for Flutter widgets.

## Step 1: Validation & Setup
Run these steps in the package that owns the widget (usually `packages/app_ui/`).

1. **Check Dependencies**: Ensure `alchemist` is present in the `dev_dependencies` of `pubspec.yaml`. If it is missing, install it:
   ```bash
   flutter pub add --dev alchemist
   ```
2. **Test Config**: Ensure `<package>/test/flutter_test_config.dart` sets the global `AlchemistConfig`, including the app theme — see [references/alchemist-setup.md](references/alchemist-setup.md). If the file already exists (the app root `test/flutter_test_config.dart` registers mappers), never replace it: keep its setup first and wrap only `testMain`.
3. **Directory Structure**: Do not create golden folders by hand. Alchemist writes `goldens/ci/` and `goldens/<platform>/` next to the test file itself.

## Step 2: Test Scaffolding
Create the test file named `[widget_name]_golden_test.dart`, mirroring the widget's path (e.g. under `packages/app_ui/test/src/widgets/`).

1. **Imports**: Import the necessary packages (`package:flutter_test/flutter_test.dart` and `package:alchemist/alchemist.dart`).
2. **Fonts**: `goldenTest` loads the app fonts itself; no separate font-loading call (as in `golden_toolkit`) is needed.

## Step 3: Implementation
Implement the test using `alchemist` APIs instead of the standard `testWidgets`.

1. **Use `goldenTest`**: Define your test using the `goldenTest` function.
2. **Theme**: `goldenTest` has **no `theme:` parameter**, and wrapping the builder in `Theme` does not reach Alchemist's `MaterialApp`. Set the theme through `AlchemistConfig(theme: …)`, built from the `app_ui` theme classes the same way `packages/app_ui/test/helpers.dart` does; otherwise `context.$.colors` throws. For a dark variant, wrap that test in `AlchemistConfig.runWithConfig(config: AlchemistConfig.current().copyWith(theme: …), run: …)`.
3. **Mock Externalities**:
   - Disable or replace infinite animations (e.g., `CircularProgressIndicator`).
   - Mock network image requests (e.g., using `mocktail_image_network` or `network_image_mock`).
4. **Matrix Testing**: Use `GoldenTestGroup` and `GoldenTestScenario` to lay out all possible widget states (e.g., loading, success, error) within a single test execution. Cover light and dark mode at minimum (see **Theme**), and text scaling with the `textScaleFactor:` parameter of `goldenTest`.

## Step 4: Generation and Verification
1. **Generate Goldens**: Run the following command to generate or update the reference images:
   ```bash
   flutter test --update-goldens
   ```
2. **Verify Output**: Check that the `.png` files were correctly generated in `goldens/ci/` (commit these) and `goldens/<platform>/` (local reference only) next to the test.
3. **Gitignore Failures**: Ensure `**/failures/` is in the project's `.gitignore` so test failure artifacts are not accidentally committed.

## Step 5: Updating Existing Goldens
If you are modifying an existing widget that already has golden tests, run the update command (`flutter test --update-goldens`) to regenerate the images. **Never modify the `.png` files manually.**
