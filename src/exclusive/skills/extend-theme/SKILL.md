---
name: extend-theme
description: Adds or changes a design-system color token or typography style in packages/app_ui across all four theme variants (light, dark, high-contrast light and dark). Use when a design needs a color or text style the theme doesn't have.
---

# Theme Extension Skill

This skill defines the process for adding or modifying a design token in
`packages/app_ui`'s theme system, which is built on two
`ThemeExtension`s — `AppColors` and `AppTextTheme` — each implemented in
**four variants**.

## 1. Structure

```text
packages/app_ui/lib/src/
├── colors/
│   ├── app_colors.dart                    # Base ThemeExtension: fields, copyWith, lerp
│   ├── app_colors_light.dart
│   ├── app_colors_dark.dart
│   ├── app_colors_high_contrast_light.dart
│   └── app_colors_high_contrast_dark.dart
├── typography/
│   ├── app_text_theme.dart                # Base ThemeExtension: fixed M3 type scale
│   └── text_theme_native.dart
└── themes/
    ├── app_theme.dart                     # Composes colors + textTheme into ThemeData
    ├── app_theme_light.dart
    ├── app_theme_dark.dart
    ├── app_theme_high_contrast_light.dart
    └── app_theme_high_contrast_dark.dart
```

The tree shows the shape, not a live inventory: list the color variants with
`ls packages/app_ui/lib/src/colors/` and the typography presets with
`grep -rl "extends AppTextTheme" packages/app_ui/lib/src/typography`.

Access at the call site is always through the `context.$` shorthand
(`packages/app_ui/lib/src/tokens/app_tokens.dart`), never
`Theme.of(context).extension<...>()` directly:

```dart
context.$.colors.primary
context.$.style.bodyLarge
```

## 2. Adding a New Color Token

There is **no per-variant token map** — `AppColors` is a fixed
constructor with one field per token, so a new token must be added to
every layer:

1. **`app_colors.dart`** (base class): add the field, the constructor
   parameter, the `copyWith` parameter + fallback, and the `lerp` entry
   (`Color.lerp(fieldName, other.fieldName, t)!`). Every list must be
   updated together or the extension breaks.
2. **Each of the 4 variant files** (`app_colors_light.dart`,
   `app_colors_dark.dart`, `app_colors_high_contrast_light.dart`,
   `app_colors_high_contrast_dark.dart`): supply a concrete `Color` value
   for the new field in the `super(...)` call.
3. Pick values by **role, not by copying an existing color** — check
   whether an existing token already fits before adding a new one (a new
   token is for a genuinely new semantic role, e.g. `warning`/`onWarning`,
   not a one-off shade).
4. **Add tokens in pairs**: a surface color comes with its content color
   (`<x>` + `on<x>`, e.g. `warning` + `onWarning`), added together.
5. **Confirm with the user** before adding a new token, especially one
   suggested by a design (see the `design-to-code` skill) — name, role and
   values for all four variants.

### Contrast requirement (WCAG AA)

For every `on<X>` / `<X>` pair (e.g. `onWarning` over `warning`), verify
a contrast ratio of at least **4.5:1** for normal text (3:1 for large
text/UI components) in all four variants — the two high-contrast variants
must clear a visibly larger margin than the standard light/dark ones, not
just repeat the same values. See `flutter_accessibility` rule.

## 3. Modifying a Typography Style

`AppTextTheme` is a **fixed Material 3 type scale** (`displayLarge` …
`labelSmall`, plus `any`) — it is not a token map either. Typography
presets subclass it (e.g. `TextThemeNative`); the app picks one in
`lib/src/utils/theme_utils.dart` and passes the same instance to all four
theme variants, so typography does not vary per variant. Adding a
new *named* style means adding a field to the base class (constructor,
`copyWith`, `lerp`) and updating every preset's constructor call, the same
fan-out as color tokens above; prefer reusing one of the 15 existing named
styles (or `any.copyWith`) unless there's a concrete, recurring need.

To change the *value* of an existing style, edit its `TextStyle` in the
preset (e.g. `packages/app_ui/lib/src/typography/text_theme_native.dart`).
A platform-specific typography is a new preset, returned from
`lib/src/utils/theme_utils.dart`.

## 4. Wiring Into `ThemeData`

`AppTheme.themeData` (`themes/app_theme.dart`) already forwards both
`AppColors` and `AppTextTheme` into `ThemeData.extensions`, and mirrors
select color fields into `ThemeData.colorScheme`/`appBarTheme` for
Material widgets that don't read `ThemeExtension`s. A new token does
**not** need a `ThemeData` mirror unless a stock Material widget
specifically needs it (e.g. wiring a new semantic color into
`ColorScheme`) — most new tokens are only ever read via `context.$`.

## 5. Verification

```bash
melos run analyze
melos run coverage        # if app_ui has affected tests
```

If any widget golden test captures the affected variant, regenerate per
the `flutter-golden-testing` skill (`flutter test --update-goldens`) and
review the diff — a token change is a visual change by definition.
