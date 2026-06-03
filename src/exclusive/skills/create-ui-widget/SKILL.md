---
name: create-ui-widget
description: >
  Process for building, exporting, and registering reusable UI components
  in the packages/app_ui package. References design-to-code.md for design
  tokens (typography, colors, spacing).
---

# UI Widget Creation Skill

This skill defines the process for adding new reusable UI widgets to the
`packages/app_ui/` package.

> [!NOTE]
> For details on mapping Figma designs, typography, HSL colors, spacing,
> and asset generation, refer to the [Design-to-Code Skill](design-to-code.md).

## 1. Directory Structure

Widgets must be placed in `packages/app_ui/lib/widgets/` by category:

```text
packages/app_ui/lib/widgets/
├── buttons/
│   └── primary_button.dart    # Class name: YzPrimaryButton
├── layout/
│   └── web/
│       └── scaffold_web.dart  # Class name: YzScaffoldWeb
└── registry.md                # Widget registry document
```

## 2. Implementation Rules

Follow these rules when implementing a widget in `app_ui`:

- **Naming**: Class names must prefix with `Yz` (e.g. `YzPrimaryButton`). File
  names must be `snake_case` without `yz_` prefix (e.g. `primary_button.dart`).
- **Web suffix**: If a web variant exists for a shared concept, append `Web`
  (e.g., `YzScaffoldWeb`).
- **No Helper Functions**: Do not use helper methods like `_buildHeader()`.
  Split components into **private classes** (e.g., `_Header`) within the same
  file.
- **Externalize Text**: Never hardcode user-facing strings in `app_ui`. Always
  pass them as parameters so the feature views can handle translations.
- **Configuration Models**: If a widget has complex parameters, create a
  dedicated config class in the same file (e.g., `YzPanelConfig`).

### 2.1 Example Implementation

```dart
import 'package:flutter/material.dart';

class YzCard extends StatelessWidget {
  const YzCard({
    required this.title,
    required this.onTap,
    super.key,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(title),
      ),
    );
  }
}
```

## 3. Exports

Always export your new widget in the root library files:
- Mobile/Shared widgets: `packages/app_ui/lib/app_ui.dart`
- Web-specific widgets: `packages/app_ui/lib/app_ui_web.dart`

## 4. Registering the Widget

Add the widget to the [registry.md](../../packages/app_ui/lib/widgets/registry.md) with:
- Widget name and a brief description.
- Example usage block.
