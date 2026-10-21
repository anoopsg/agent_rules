---
trigger: always
---

# app_ui Imports (Launchpad)
- Outside `packages/app_ui`, ALWAYS import app_ui with the `ui` prefix: `import 'package:app_ui/app_ui.dart' as ui;` (same for `app_ui_web.dart`).
- NEVER import app_ui without the prefix, and NEVER use another prefix or `show`/`hide` on it.
- Reference every app_ui symbol through the prefix: `ui.PrimaryButton`, `ui.AppScaffold`, `ui.AppSpacing.md`, `ui.showSnackBar`.
- Keep `const` where possible: `const ui.Avatar(label: 'A')`.
- Theme extensions (`context.$`) need no prefix.
- Inside `packages/app_ui`, import `package:app_ui/app_ui.dart` without a prefix.
