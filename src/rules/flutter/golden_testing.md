---
trigger: auto
description: Golden testing guidelines and UI regression testing for Flutter widgets. Apply when writing or modifying widget tests, or performing visual regression tests across devices.
---

# Flutter Golden Testing & UI Regression

- **Automated Golden Test Pipeline:** After making any UI modifications, you MUST automatically run the golden tests (e.g., `flutter test`) to verify that the UI hasn't broken across different screen sizes and states. If the changes are expected, explicitly update the golden files (e.g., `flutter test --update-goldens`).
- **Strict Golden Coverage:** If a golden test does not exist for the modified widget, you MUST write one before completing the task.
- **Dependencies Setup:** Before writing golden tests, verify that a modern testing package (e.g., `alchemist`) is in `dev_dependencies` of `pubspec.yaml`. If missing, install it (`flutter pub add --dev alchemist`) to enable advanced, declarative testing APIs.
- **Alchemist Framework Features:** Leverage `alchemist`'s full feature set for robust tests:
  - **`goldenTest` API:** Use `goldenTest` instead of `testWidgets` for automatic CI detection, platform-agnostic rendering, and advanced pump behaviors.
  - **Matrix Testing:** Use `GoldenTestGroup` and `GoldenTestScenario` to map out all widget states (loading, success, error, empty), multiple themes (Light/Dark), and device sizes in a single, compiled golden image.
  - **Inline Configurations:** Apply `theme` and `textScaleFactor` overrides directly in the `GoldenTestGroup` or `goldenTest` scope to verify accessibility scaling (e.g., `textScaleFactor: 2.0`) and dark mode without boilerplate wrapper widgets.
  - **CI & Platform Independence:** Utilize `AlchemistConfig` to enforce `ciGoldensConfig` on CI pipelines. This guarantees deterministic rendering (e.g., forcing a specific OS rendering engine) and ensures zero pixel deviations between developers and CI.
  - **Typography & Assets:** Ensure fonts and assets are loaded before tests run (e.g., `loadAppFonts()`), so text renders accurately instead of falling back to the Ahem font (black boxes), which can mask layout issues.
- **Avoid Platform Differences:** Run golden tests in a consistent environment (e.g., macOS or Linux CI) as text rendering engines vary slightly across OSs. Use a tolerance threshold if minor pixel shifting is expected.
- **Updating Goldens:** Never modify `.png` reference files manually. Only update them by running `flutter test --update-goldens`.
- **Organization:** Store golden reference images in a `goldens/` directory located right next to the test file.
- **Handling Animations:** Infinite animations (e.g., `CircularProgressIndicator`, Lottie) will cause test timeouts. The agent MUST mock, disable, or replace these animations with static equivalents when running golden tests.
- **Mocking Network Images:** Real network requests in tests will fail or cause flakiness. Use packages like `mocktail_image_network` or `network_image_mock` to stub HTTP image requests before pumping the widget.
- **Gitignore Failures:** When golden tests fail, Flutter generates diff images in a `failures/` directory. Ensure `**/failures/` is added to the project's `.gitignore` to prevent committing broken test artifacts.
