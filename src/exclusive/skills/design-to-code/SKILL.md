---
name: design-to-code
description: >
  Outlines the process for converting Figma designs into
  a structured, platform-aware Flutter implementation.
---

# Design-to-Code Skill

This skill outlines the process for converting Figma
designs into a structured, platform-aware Flutter
implementation.

## 1. Asset Management

### 1.1 Organization
All assets must be placed in the
`packages/app_ui/assets/` directory following this
structure:
- **SVGs**: `assets/svg/`
- **Icons**: `assets/svg/icons/`
- **SVG Images**: `assets/svg/images/`
- **Raster Images**: `assets/images/`
  (PNG, JPEG, WebP — e.g., photos, hero banners)
- **Lottie Animations**: `assets/lottie/`

### 1.2 Verification & Generation
1. **Verify**: Before adding an asset, check
   `packages/app_ui/assets/` to see if it already
   exists.
2. **Add**: Place the new asset in the appropriate
   folder.
3. **Generate**: Run `melos run generate` to update
   the `AppAssets` class.
4. **Usage**: Use `AppAssets` to reference the asset
   in code:
   ```dart
   AppAssets.icons.google.svg();
   ```

### 1.3 Handling Missing or Unplaced Assets
When extracting from Figma via the MCP server, assets
might not be marked for export or could be missing
entirely:
1. **Detection**: If the MCP server cannot locate or
   export an expected visual asset.
2. **Placeholders**: Use a standardized placeholder
   widget to maintain layout integrity. Always include
   a `TODO` comment for traceability:
   ```dart
   // TODO(design): Replace with exported asset.
   //   @Source: <Page> > <Frame> > <Element>.
   Container(
     width: 120,
     height: 120,
     decoration: BoxDecoration(
       color: context.$.colors.surface,
       borderRadius: BorderRadius.circular(
         AppSpacing.sm,
       ),
     ),
     child: const Center(
       child: Icon(Icons.image_outlined),
     ),
   )
   ```
3. **Notification**: Explicitly notify the user that
   the asset was missing from the exportable Figma
   assets and request they mark it for export or
   provide it manually.

## 2. Typography & Colors

### 2.1 Colors
1. Use curated, HSL-tailored colors defined in
   `app_colors.dart`.
2. Avoid hardcoded hex values in UI; always use
   `context.$.colors`.

#### Handling Unstructured Palettes
If the design lacks a defined palette or uses
inconsistent, ad-hoc hex codes (e.g., from junior
designers):
1. **Consolidate**: Identify the core, most frequently
   used colors representing the brand or theme.
2. **Map**: Map these extracted core colors to the
   existing semantic tokens in `app_colors.dart`
   (e.g., `primary`, `secondary`, `surface`).
3. **Consult**: Strictly prohibit hardcoding random hex
   values. If a new semantic token is genuinely needed
   to represent a consistent design pattern, consult
   the user rather than creating ad-hoc colors.

### 2.2 Typography
1. **Reuse**: Maximize reuse of existing styles in
   `AppTextTheme`.
2. **Customization**: If a specific style isn't
   available, use the `any` field combined with
   `copyWith` to maintain consistency while allowing
   flexibility.
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
1. Map Figma spacing values directly to `AppSpacing`
   tokens.
2. **Nearest Match Rule**: If an exact token does not
   exist for a Figma value, round to the **nearest**
   available token. If equidistant, prefer the
   **smaller** token (e.g., if Figma shows 18px, use
   `AppSpacing.md` (16px) over `AppSpacing.lg` (20px)
   since 18 is equidistant).
3. Always prefer `AppSpacing` constants over hardcoded
   double values.

### 2.4 Internationalization (i18n)
1. **No Hardcoded Strings**: Never hardcode
   user-facing strings in the UI.
2. **Translation Files**: Add strings to the
   appropriate domain section in the i18n files
   (using `slang`).
3. **Usage**: Access translations using `context.$.tr`
   (e.g., `context.$.tr.auth.login.title`).
4. **Generation**: Run `melos run translate` after
   updating translation files.

## 3. Atomic Design & Widgets

Break the design into reusable components. Before
creating anything:

1. **Check Widgets**: Verify `packages/app_ui/lib/widgets/`
   for existing components and their design `@Source`.
   * Use `grep_search` to find matching `@Source`
     breadcrumbs (e.g., `Login > Hero > CTA`).
   * Do not extract a component that is already
     synced.
2. **Deduplication**: A reusable widget (e.g., a
   primary button) may appear on many pages. Match
   by **visual similarity** — not by page location.
   To efficiently find matches in a large codebase:
   * **Search**: Use `grep_search` on the widgets
     directory for specific `@Style` or `@Layout`
     tokens (e.g., `@Style:.*Bg: primary`).
   * **Inspect**: Use `view_file` to read the specific
     candidate `.dart` files to verify properties.
   If the element visually matches, reuse that class.
   Do **not** create a duplicate.
3. **Imports**: Always consume via
   `package:app_ui/app_ui.dart`. Avoid internal file
   imports.

> [!NOTE]
> For widget implementation rules (naming, structure,
> exports, and code annotations), follow the
> [UI Widget Creation Skill](create-ui-widget.md).

## 4. Feature Implementation

### 4.1 Feature Setup
Follow the [Feature Creation Skill](create-feature.md)
to set up the directory structure.
- Complex features (like Auth) should have sub-folders
  for each page (e.g., `auth/login/`).
- **Permissions**: If the target feature folder does
  not exist, you **must** ask for user permission
  before creating the directory structure.

### 4.2 Building Views
Implement the view for the target platform
(e.g., mobile):
- `login_view.dart` (Mobile)
- If required later, implement
  `login_view_web.dart` (Web).
- Refer to
  [Feature Creation Skill](create-feature.md) for
  state binding and performance optimization
  (MemoizedView).
- Use `AppSpacing` and `AppAssets` consistently.

## 5. Figma Tracking (Manifest & Code)

To maintain a single source of truth and prevent
redundant extraction, we use a Code-as-Truth approach
for widgets, and a dedicated manifest for file tracking.

### 5.1 Project-Level Tracking
`packages/app_ui/figma_manifest.yaml` acts as the
manifest to track active Figma file(s) and sync status:
```yaml
figma_file_ids:
  - id: "<figma_file_id_1>"
    name: "Main App Design"
last_sync: "<ISO 8601 timestamp>"
```

### 5.2 Component Tracking (Code-as-Truth)
We do not use a centralized markdown table.
Instead, components are tracked directly via doc-comment
annotations (see [UI Widget Creation Skill](create-ui-widget.md#4)).

- **Tracking**: Ensure every new component has the strict
  4-line `@UI`, `@Source`, `@Style`, and `@Layout`
  annotations directly above the class.

> [!NOTE]
> **Design Evolution**: If a Figma design has changed
> since the last sync, update the `@Status` of the
> affected widget's doc-comment to `outdated`.
