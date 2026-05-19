---
name: design-to-code
description: >-
  Convert a Figma design into Flutter UI using AppAssets, AppSpacing,
  AppTextTheme, and the Yz widget kit. Use when implementing a screen
  or component from a Figma reference, syncing design tokens, or
  registering a new reusable widget in app_ui.
---
# Design-to-Code Skill

This skill outlines the process for converting Figma designs into a structured, 
platform-aware Flutter implementation.

## 1. Asset Management

### 1.1 Organization
All assets must be placed in the `packages/app_ui/assets/` directory following 
this structure:
- **SVGs**: `assets/svg/`
- **Icons**: `assets/svg/icons/`
- **Images**: `assets/svg/images/` (if using SVGs for illustrations)

### 1.2 Verification & Generation
1. **Verify**: Before adding an asset, check `packages/app_ui/assets/` to see 
   if it already exists.
2. **Add**: Place the new asset in the appropriate folder.
3. **Generate**: Run `melos run generate` to update the `AppAssets` class.
4. **Usage**: Use `AppAssets` to reference the asset in code:
   ```dart
   AppAssets.icons.google.svg();
   ```

## 2. Typography & Colors

### 2.1 Colors
1. Use curated, HSL-tailored colors defined in `app_colors.dart`.
2. Avoid hardcoded hex values in UI; always use `context.$.colors`.

### 2.2 Typography
1. **Reuse**: Maximize reuse of existing styles in `AppTextTheme`.
2. **Customization**: If a specific style isn't available, use the `any` field 
   combined with `copyWith` to maintain consistency while allowing flexibility.
   ```dart
   Text(
     'Design Text',
     style: context.$.style.any.copyWith(
       fontSize: 18,
       fontWeight: FontWeight.bold,
       color: context.$.colors.primary,
     ),
   )
   ```
### 2.3 Spacing
1. Map Figma spacing values directly to `AppSpacing` tokens.
2. **Nearest Match Rule**: If an exact token does not exist for a Figma value, 
   use the nearest available token (e.g., if Figma shows 17px, use 
   `AppSpacing.md` (16px) or `AppSpacing.lg` (20px)).
3. Always prefer `AppSpacing` constants over hardcoded double values.

### 2.4 Internationalization (i18n)
1. **No Hardcoded Strings**: Never hardcode user-facing strings in the UI.
2. **Translation Files**: Add strings to the appropriate domain section in the 
   i18n files (using `slang`).
3. **Usage**: Access translations using `context.$.tr` (e.g., 
   `context.$.tr.auth.login.title`).
4. **Generation**: Run `melos run translate` after updating translation files.

## 3. Atomic Design & Widgets

### 3.1 Principles & Categorization
Break the design into reusable components in `packages/app_ui/lib/widgets/`.

- **Imports**: Always use the public entry point `package:app_ui/app_ui.dart` 
  for all consumers of the UI kit. Avoid internal file imports.

- **Categorization**: Place widgets in appropriate sub-folders (e.g., `buttons/`, 
  `inputs/`, `layout/`, `cards/`).
- **Web-Only**: Web-specific widgets go in `widgets/web/<category>/`.
- **No Helper Functions**: NEVER use methods to build UI (e.g., `Widget _buildFoo()`). 
  If a widget is complex, split it into **private classes** (e.g., `_Foo`) 
  within the same file.
- **Configuration Models**: If a widget requires many parameters or has nested 
  complex components, create a dedicated configuration model in the same file 
  (e.g., `YzActionPanelModel` for `YzActionPanel`).
- **Naming**: 
  - Always prefix widget classes with `Yz` (e.g., `YzPrimaryButton`).
  - Filenames use `snake_case` without the `yz_` prefix (e.g., `primary_button.dart`).
  - If a web variant exists for a shared concept, use the `Web` suffix (e.g., `YzScaffoldWeb`).
- **Externalize Text**: Never hardcode labels or hints inside `app_ui` widgets. 
  Pass them as properties from the feature view.
  ```dart
  // GOOD: Label is passed from above
  const YzPrimaryButton({required this.label, ...});

  // BAD: Label is hardcoded inside the widget
  Widget build(BuildContext context) => const Text('Submit');
  ```

### 3.2 Widget Registry (MANDATORY)
1. **Lookup**: Before creating a widget, check `packages/app_ui/lib/widgets/registry.md`.
2. **Register**: After creating a reusable widget, add it to the root `packages/app_ui/lib/widgets/registry.md` with:
   - Name and description.
   - Usage example.
   - Design reference if applicable.

## 4. Feature Implementation

### 4.1 Feature Setup
Follow the [Feature Creation Skill](../create-feature/SKILL.md) to set up the 
directory structure.
- Complex features (like Auth) should have sub-folders for each page (e.g., 
  `auth/login/`).
- **Permissions**: If the target feature folder does not exist, you **must** 
  ask for user permission before creating the directory structure.

### 4.2 Building Views
Implement the view for the target platform (e.g., mobile):
- `login_view.dart` (Mobile)
- If required later, implement `login_view_web.dart` (Web).
- Refer to [Feature Creation Skill](../create-feature/SKILL.md) for state binding and performance optimization (MemoizedView).
- Use `AppSpacing` and `AppAssets` consistently.

## 5. Workflow Summary
1. **Analyze Design**: Use the **Figma MCP server** to inspect the design file, 
   extract tokens (colors, typography, spacing), and identify atoms, molecules, 
   and organisms.
2. **Check Assets**: Verify and add missing SVGs/Icons using the Figma MCP 
   to export assets if necessary.
3. **Check Widgets**: Verify `widgets/registry.md` for existing components.
4. **Build UI Kit**: Implement missing atoms/molecules in `app_ui`.
5. **Implement Feature**: Apply components to the feature's view layer.
6. **Verify in Sandbox**: Run the [golden-sandbox](../../../skills/golden-sandbox/SKILL.md) 
   workflow across the device/theme matrix before marking the task complete. 
   Do not skip; UI parity with the design is verified by goldens, not by inspection.