---
name: create-ui-widget
description: Creates or changes a reusable widget in packages/app_ui — structure, naming, tokens, accessibility, exports and @UI annotations. Use when adding a shared UI component. From a Figma design start with design-to-code; new color or text tokens use extend-theme.
---

# UI Widget Creation Skill

This skill defines the process for adding new reusable UI widgets to the
`packages/app_ui/` package.

> [!NOTE]
> For details on mapping Figma designs, typography, HSL colors, spacing,
> and asset generation, refer to the [Design-to-Code Skill](../design-to-code/SKILL.md).

## 1. Directory Structure

Widgets must be placed in `packages/app_ui/lib/src/widgets/` by category; web-only widgets go under `packages/app_ui/lib/src/widgets/web/`:

```text
packages/app_ui/lib/src/widgets/<category>/<snake_name>.dart
packages/app_ui/lib/src/widgets/web/<category>/<snake_name>_web.dart
```

For example, `packages/app_ui/lib/src/widgets/buttons/primary_button.dart` holds `PrimaryButton`. List the existing categories with `ls packages/app_ui/lib/src/widgets/`.

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
  file. For what belongs in `app_ui` versus a feature view, see the view
  composition rule in the [Feature Creation Skill](../create-feature/SKILL.md) (§3.5).
- **Default Sizes**: Default dimensions (height, width, etc.) are constructor
  parameters with their defaults set in the constructor, not private
  constants outside the class (e.g., avoid `const _headerHeight = 295.0;`).
- **Externalize Text**: Never hardcode user-facing strings in `app_ui`. Always
  pass them as parameters so the feature views can handle translations.
  This includes formatted values (dates, counts) and screen-reader labels:
  take them preformatted.
- **Configuration Models**: If a widget has complex parameters, create a
  dedicated `<Widget>Config` class in the same file (e.g.,
  `NotificationTileConfig` in
  `packages/app_ui/lib/src/widgets/tiles/notification_tile.dart`). The
  feature builds it in an extension on its model that receives `context`
  and preformats every label (e.g. `toTileConfig` in
  `lib/src/features/notifications/view/notification_tile_config.dart`).
- **Accessibility**: Every swipe or long-press action also gets a
  `Semantics` custom action (`customSemanticsActions`), so screen readers
  can trigger it.
- **RTL**: Use directional APIs (`EdgeInsetsDirectional`,
  `AlignmentDirectional`, `PositionedDirectional`), never left/right.
- **Reuse Primitives**: Compose existing `app_ui` primitives instead of
  re-creating them (e.g. `Loader`, never `CircularProgressIndicator`).

### 2.1 Example Implementation

Inside `app_ui`, import `package:material_ui/material_ui.dart` (never
`package:flutter/material.dart`) and `package:app_ui/app_ui.dart` unprefixed.

```dart
import 'package:app_ui/app_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Content card for displaying simple text.
///
/// ---
/// @UI: Card | Content
/// @Source: — | Status: manual
/// @Style: Bg: surface | Text: bodyLarge | Radius: md
/// @Layout: Padding: md
class const ContentCard({
  required final String title,
  required final VoidCallback onTap,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.$.colors.surface,
      borderRadius: .circular(AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const .all(AppSpacing.md),
          child: Text(title, style: context.$.style.bodyLarge),
        ),
      ),
    );
  }
}
```

## 3. Exports

Always export your new widget in its barrel file (never add exports to the
root library files directly):
- Mobile/Shared widgets: `packages/app_ui/lib/src/widgets/widgets.dart` (re-exported by `packages/app_ui/lib/app_ui.dart`)
- Web-specific widgets: `packages/app_ui/lib/src/widgets/web/web.dart` (re-exported by `packages/app_ui/lib/app_ui_web.dart`)

## 4. Widget Annotations (Code-as-Truth)

We do **not** use a centralized `registry.md`. Instead, every reusable widget must include a strict 4-line doc-comment block directly above the class definition. This allows AI agents to rapidly filter and deduplicate widgets across the entire codebase with a plain text search (e.g. `grep -rn "@UI:" packages/app_ui/lib/src/widgets`).

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
