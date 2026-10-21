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
> and asset generation, refer to the [Design-to-Code Skill](../design-to-code/SKILL.md).

## 1. Directory Structure

Widgets must be placed in `packages/app_ui/lib/src/widgets/` by category:

```text
packages/app_ui/lib/src/widgets/
├── buttons/
│   └── primary_button.dart    # Class name: PrimaryButton
├── layout/
│   └── web/
│       └── scaffold_web.dart  # Class name: AppScaffoldWeb
```

## 2. Implementation Rules

Follow these rules when implementing a widget in `app_ui`:

- **Naming**: Class names have no prefix (e.g. `PrimaryButton`). If a name
  clashes with a Material widget, prefix it with `App` (e.g. `AppScaffold`).
  File names must be `snake_case` (e.g. `primary_button.dart`).
- **Generic Naming**: Always use generic, domain-agnostic names for widgets. For example, name a button `PrimaryButton` rather than `LoginButton`, even if it is currently only used on a specific screen.
- **Web suffix**: If a web variant exists for a shared concept, append `Web`
  (e.g., `AppScaffoldWeb`).
- **No Helper Functions**: Do not use helper methods like `_buildHeader()`.
  Split components into **private classes** (e.g., `_Header`) within the same
  file (this applies to widgets inside `app_ui`, NOT feature views).
- **Externalize Text**: Never hardcode user-facing strings in `app_ui`. Always
  pass them as parameters so the feature views can handle translations.
- **Configuration Models**: If a widget has complex parameters, create a
  dedicated config class in the same file (e.g., `PanelConfig`).

### 2.1 Example Implementation

```dart
import 'package:flutter/material.dart';

/// Content card for displaying simple text.
///
/// ---
/// @UI: Card | Content
/// @Source: — | Status: manual
/// @Style: Bg: surface | Radius: md
/// @Layout: Padding: md
class const ContentCard({
  required final String title,
  required final VoidCallback onTap,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const .all(AppSpacing.md),
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

## 4. Widget Annotations (Code-as-Truth)

We do **not** use a centralized `registry.md`. Instead, every reusable widget must include a strict 4-line doc-comment block directly above the class definition. This allows AI agents to rapidly filter and deduplicate widgets across the entire codebase using `grep_search`.

### The Annotation Schema

The block must be separated by a horizontal rule (`---`) and consists of 4 grouped `@` tags:

1. `@UI:` Category and Intent (e.g., `Button | Primary CTA`).
2. `@Source:` Figma breadcrumb and sync status (e.g., `Login > Hero > CTA | Status: synced`).
3. `@Style:` Colors and shapes (`Bg`, `Text`, `Radius`, `Border`, `Shadow`).
4. `@Layout:` Spacing and structure (`Padding`, `Size`, `Icon`).

### Rules

1. **Omit Defaults**: To keep the footprint minimal, only include properties that are actively styled. If a widget has no border or shadow, do not write `Border: none`. Omit them entirely.
2. **80-Character Limit**: The grouped lines must not exceed 80 characters. If a line is too long, wrap it to a new line with the same tag prefix.

### Dictionary Keys

Use exact keys and tokens (e.g., `Bg: primary | Radius: pill`):
- `Bg`: Semantic color (e.g., `primary`, `surface`, `transparent`)
- `Text`: Typography token (e.g., `labelLarge`, `bodyMedium`)
- `Radius`: Shape (e.g., `sm`, `md`, `pill`)
- `Border`: Outline style (e.g., `outline`, `error`)
- `Shadow`: Elevation (e.g., `sm`, `md`)
- `Padding`: Spacing (e.g., `sm`, `md`, `lg`)
- `Size`: Layout behavior (e.g., `expanded`, `shrink`, `fixed`)
- `Icon`: Presence (e.g., `leading`, `trailing`, `only`)
