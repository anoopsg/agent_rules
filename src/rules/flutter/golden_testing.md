---
trigger: auto
description: Golden testing guidelines and UI regression testing for Flutter widgets. Apply when writing or modifying widget tests, or performing visual regression tests across devices.
---

# Flutter Golden Testing Constraints

When modifying Flutter widgets or writing tests, adhere to the following constraints. For a step-by-step implementation guide, invoke the **flutter-golden-testing** skill.

- **Automated Verification:** After modifying UI, you MUST run golden tests to verify regressions. If the changes are intentional, update the goldens (`flutter test --update-goldens`).
- **Strict Coverage:** If a modified widget lacks a golden test, you MUST write one before completing the task.
- **Framework & API:** Always use the `alchemist` package and its `goldenTest` API instead of the default `testWidgets`.
- **Immutability of References:** NEVER manually edit `.png` reference files. Only update them via the `--update-goldens` flag.
- **Flakiness Prevention:**
  - Mock, disable, or replace infinite animations to prevent test timeouts.
  - Stub network image requests (e.g., using `mocktail_image_network`) to prevent HTTP failures during testing.
- **Platform Consistency:** Golden tests should be run in a consistent environment (e.g., macOS or CI) to avoid text rendering engine discrepancies. Use `AlchemistConfig` to enforce `ciGoldensConfig`.
- **Gitignore:** Ensure `**/failures/` is ignored in `.gitignore` to prevent committing diff images.
