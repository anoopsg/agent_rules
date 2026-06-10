---
name: flutter-golden-testing
description: Step-by-step workflow for creating, configuring, and updating Flutter golden tests using the Alchemist package.
---

# Flutter Golden Testing Skill

This skill outlines the step-by-step process for implementing and updating golden tests for Flutter widgets.

## Step 1: Validation & Setup
1. **Check Dependencies**: Ensure `alchemist` is present in the `dev_dependencies` of `pubspec.yaml`. If it is missing, install it:
   ```bash
   flutter pub add --dev alchemist
   ```
2. **Directory Structure**: Create a `goldens/` directory adjacent to your target test file to store the generated `.png` reference files.

## Step 2: Test Scaffolding
Create the test file named `[widget_name]_test.dart` (or `[widget_name]_golden_test.dart`).

1. **Imports**: Import the necessary packages (`package:flutter_test/flutter_test.dart` and `package:alchemist/alchemist.dart`).
2. **Setup Fonts/Assets**: Call `loadAppFonts()` (if applicable) before running the tests to prevent text from rendering as the Ahem font.

## Step 3: Implementation
Implement the test using `alchemist` APIs instead of the standard `testWidgets`.

1. **Use `goldenTest`**: Define your test using the `goldenTest` function.
2. **Mock Externalities**:
   - Disable or replace infinite animations (e.g., `CircularProgressIndicator`).
   - Mock network image requests (e.g., using `mocktail_image_network` or `network_image_mock`).
3. **Matrix Testing**: Use `GoldenTestGroup` and `GoldenTestScenario` to lay out all possible widget states (e.g., loading, success, error) and variations (light/dark mode, text scaling) within a single test execution.

## Step 4: Generation and Verification
1. **Generate Goldens**: Run the following command to generate or update the reference images:
   ```bash
   flutter test --update-goldens
   ```
2. **Verify Output**: Check that the `.png` files were correctly generated in the `goldens/` directory.
3. **Gitignore Failures**: Ensure `**/failures/` is in the project's `.gitignore` so test failure artifacts are not accidentally committed.

## Step 5: Updating Existing Goldens
If you are modifying an existing widget that already has golden tests, run the update command (`flutter test --update-goldens`) to regenerate the images. **Never modify the `.png` files manually.**
