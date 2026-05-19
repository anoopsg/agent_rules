# Flutter Golden Testing

- **MUST run goldens before reporting any UI task complete.** No exceptions for "trivial" tweaks (padding, color, single-line text, refactor). If a widget tree was touched, goldens run.
- **Turn summary MUST disclose golden status.** Include exactly one of: `goldens: <N> green`, `goldens: <N> green, <M> regenerated (<reason>)`, or `goldens: skipped because <verified-no-visual-change reason>`. Silent skip is a rule violation.
- Cover the device matrix: small phone (375x667), large phone (414x896), tablet (768x1024), desktop (1280x800). Include light + dark themes and text scales 1.0 and 1.5.
- On a diff: classify regression vs. intentional. Fix regressions first; update goldens only for intentional changes.
- Pin a stable test locale, time, and text scale in `flutter_test_config.dart` to keep goldens deterministic.
- Mirror source paths under `test/goldens/` (e.g. `lib/features/login/login_view.dart` → `test/goldens/features/login/login_view_golden_test.dart`).
- Update goldens per-test only (`flutter test path/to/test.dart --update-goldens`); never repo-wide blindly.
- Never commit a failing baseline. Either fix the widget or regenerate, then commit the new images alongside the code.
- Use the `golden-sandbox` skill for the full sandbox setup, matrix, fix-loop, and disclosure format.
