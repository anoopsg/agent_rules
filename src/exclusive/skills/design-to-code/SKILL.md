---
name: design-to-code
description: Turns a Figma design into Flutter code — assets, color/text/spacing tokens, reusable app_ui widgets, localized views and Figma sync tracking. Use when implementing a screen, section or component from Figma.
---

# Design-to-Code Skill

This skill defines the process for turning a Figma frame into code: place its
assets, map its colors, text and spacing to design tokens, extract reusable
blocks into `app_ui`, then compose and localize the feature view.

## 1. Asset Management

### 1.1 Organization
All assets must be placed in the `packages/app_ui/assets/` directory following this structure:
- **Icons**: `packages/app_ui/assets/icons/` (SVG)
- **Images**: `packages/app_ui/assets/images/` (SVG illustrations and PNG, JPEG, WebP — e.g., photos, hero banners)
- **Animations**: `packages/app_ui/assets/animations/`
- **No Feature Folders**: Do not create feature-specific subfolders (e.g., `login/`, `auth/`) within these asset directories. Keep the structure flat by asset type to avoid issues if an asset is later reused in another feature.

### 1.2 Verification & Generation
1. **Verify**: Before adding an asset, check `packages/app_ui/assets/` to see if it already exists.
2. **Add**: Place the new asset in the appropriate folder.
3. **Generate**: Run `melos run generate` to update the `AppAssets` class.
4. **Usage**: Use `AppAssets` to reference the asset in code:
   ```dart
   ui.AppAssets.icons.google.svg();
   ```

### 1.3 Handling Missing or Unplaced Assets
When extracting from Figma via the MCP server, assets might not be marked for export or could be missing entirely:
1. **Detection**: If the MCP server cannot locate or export an expected visual asset.
2. **Placeholders**: Use a standardized placeholder widget to maintain layout integrity. Always include a `TODO` comment for traceability:
   ```dart
   const SizedBox(width: 120, height: 120); // TODO(design): Replace with exported asset. @Source: <Page> > <Frame> > <Element>
   ```
3. **Notification**: Explicitly notify the user that the asset was missing from the exportable Figma assets and request they mark it for export or provide it manually. **NEVER** use the Figma MCP API asset URL (`https://www.figma.com/api/mcp/asset/...`) directly in the code (e.g. via `Image.network`).

### 1.4 Asset Usage
1. **No `package:` Argument**: Generated asset widgets already resolve to `app_ui`. Never pass `package:` or define a package constant.
2. **Tint Icons**: Use `colorFilter: ColorFilter.mode(context.$.colors.x, BlendMode.srcIn)`; never edit the SVG or hardcode colors.
3. **Material Icons**: Use `Icon(Icons.x)` for stock Material icons instead of exporting SVGs.

## 2. Typography & Colors

### 2.1 Colors
1. Use the curated semantic color tokens declared in `app_colors.dart` (each theme variant sets their values in its `app_colors_*.dart` file).
2. Avoid hardcoded hex values (`Color(0xFF...)`) in UI; always use `context.$.colors`.
3. **No Private Color Classes**: Never create private static classes, state variables (e.g., `static const _color = Color(...)`), or files for colors inside views or widgets. All colors MUST be defined as tokens in `packages/app_ui/lib/src/colors/`.

#### Handling Unstructured Palettes
If the design lacks a defined palette or uses inconsistent, ad-hoc hex codes (e.g., from junior designers):
1. **Consolidate**: Identify the core, most frequently used colors representing the brand or theme.
2. **Map**: Map these extracted core colors to the existing semantic tokens in `app_colors.dart` (e.g., `primary`, `secondary`, `surface`).
3. **Consult**: Strictly prohibit hardcoding random hex values. If a new semantic token is genuinely needed to represent a consistent design pattern, consult the user rather than creating ad-hoc colors — see the `extend-theme` skill for the token-creation process.

### 2.2 Typography
1. **Reuse**: Maximize reuse of existing styles in `AppTextTheme`.
2. **Customization**: If a specific style isn't available, use the `any` field combined with `copyWith` to maintain consistency while allowing flexibility.
   ```dart
   Text('Design Text', style: context.$.style.any.copyWith(fontSize: 18, color: context.$.colors.primary))
   ```

### 2.3 Spacing
1. Map Figma spacing values directly to `AppSpacing` tokens.
2. **Nearest Match Rule**: If an exact token does not exist for a Figma value, round to the **nearest** available token. If equidistant, prefer the **smaller** token (e.g., if Figma shows 18px, use `AppSpacing.md` (16px) over `AppSpacing.lg` (20px) since 18 is equidistant).
3. Always prefer `AppSpacing` constants over hardcoded double values.

### 2.4 Internationalization (i18n)
Never hardcode user-facing text from the design. Add keys, use `context.$.tr` and regenerate as described in the `add-translations` skill. Two rules specific to building screens:

1. **Direct Localization**: Use localization directly within the respective `_view.dart` files (or their `view/_<part>.dart` files). **NEVER** pass translated strings down from parent pages or via `ViewProps`.
2. **Widget Labels**: `app_ui` widgets never translate or format; they take preformatted text through parameters or a `<Widget>Config` built by the feature (see "Configuration Models" in the [UI Widget Creation Skill](../create-ui-widget/SKILL.md)).

### 2.5 Motion & Animation
1. **Animate State Changes**: State changes shown in prototype connections or variants (e.g. `Default` → `Loading`) must animate, not snap.
2. **Prefer Implicit Widgets**: Use `AnimatedContainer`, `AnimatedSwitcher`, `AnimatedOpacity`, `AnimatedList`, `Hero`, etc. before an `AnimationController`.
3. **Motion Tokens**: Use `ui.AppDurations` and `ui.AppCurves`, wrapped in `ui.AppDurations.resolve(context, ...)` for reduced motion. Never hardcode `Duration` or `Curves.*`.
4. **Route Transitions**: Use `CustomTransitionPage` only when the design specifies a non-default transition.

## 3. Atomic Design & Widgets

Break the design into reusable components. Before creating anything:

1. **Logical Structuring**: Do not blindly mirror the exact layer structure of the Figma file. Designers sometimes take shortcuts or use non-logical groupings. Analyze the layout logically and implement a clean, efficient Flutter structure.
2. **Extract BEFORE Implementing View**: Every reusable visual block in the frame (e.g., headers, custom inputs, cards, tiles) MUST be extracted to `packages/app_ui/lib/src/widgets/` **before** you write the feature's `_view.dart` file. What stays in the feature, and where, follows the view composition rule in the [Feature Creation Skill](../create-feature/SKILL.md) (§3.5).
3. **Check Widgets**: Verify `packages/app_ui/lib/src/widgets/` for existing components and their design `@Source`.
   * Search the widgets folder for matching `@Source` breadcrumbs (e.g., `Login > Hero > CTA`): `grep -rn "@Source:" packages/app_ui/lib/src/widgets`.
   * Do not extract a component that is already synced.
4. **Deduplication**: A reusable widget (e.g., a primary button) may appear on many pages. Match by **visual similarity** — not by page location.
   To efficiently find matches in a large codebase:
   * **Search**: Search the widgets folder for specific `@Style` or `@Layout` tokens (e.g., `@Style:.*Bg: primary`).
   * **Inspect**: Read the candidate `.dart` files to verify properties. Not every widget is annotated yet, so also scan the category folders.
   If the element visually matches, reuse that class. Do **not** create a duplicate.
5. **Loading Indicators**: Use `ui.Loader` for every spinner. Never use `CircularProgressIndicator` or a custom loader.
6. **Imports**: Always consume via `import 'package:app_ui/app_ui.dart' as ui;` and reference symbols with the prefix (e.g. `ui.PrimaryButton`, `ui.AppSpacing.md`). Avoid internal file imports.

> [!NOTE]
> For widget implementation rules (generic naming, default sizes, structure, exports, and code annotations), follow the [UI Widget Creation Skill](../create-ui-widget/SKILL.md).

## 4. Feature Implementation

### 4.1 Feature Setup
Follow the [Feature Creation Skill](../create-feature/SKILL.md) to set up the directory structure.
- Complex features (like Auth) should have sub-folders for each page (e.g., `auth/login/`).
- **Permissions**: If the target feature folder does not exist, you **must** ask for user permission before creating the directory structure.

### 4.2 Building Views
Implement the view for the target platform (e.g., mobile):
- `login_view.dart` (Mobile)
- If required later, implement `login_view_web.dart` (Web).
- Refer to [Feature Creation Skill](../create-feature/SKILL.md) for state binding and performance optimization (MemoizedView).
- Use `AppSpacing` and `AppAssets` consistently.

## 5. Figma Tracking (Manifest & Code)

To maintain a single source of truth and prevent redundant extraction, we use a Code-as-Truth approach for widgets, and a dedicated manifest for file tracking.

### 5.1 Project-Level Tracking
`figma_manifest.yaml` (in the `packages/app_ui/` root) acts as the manifest to track active Figma file(s) and sync status. It answers "which Figma file is this app built from?". The template does not ship it: create it on the first sync.
```yaml
figma_file_ids:
  - id: "<figma_file_id_1>"
    name: "Main App Design"
last_sync: "<ISO 8601 timestamp>"
```

- **Re-sync check**: Before syncing, compare each file's Figma last-modified time with `last_sync`. If Figma is newer, review the synced widgets from that file and mark the changed ones `Status: outdated` (see below).
- **After a sync**: Update `last_sync`.

### 5.2 Component Tracking (Code-as-Truth)
We do not use a centralized markdown table. Instead, components are tracked directly via doc-comment annotations (see [UI Widget Creation Skill](../create-ui-widget/SKILL.md#4-widget-annotations-code-as-truth)).

- **Tracking**: Ensure every new component has the strict 4-line `@UI`, `@Source`, `@Style`, and `@Layout` annotations directly above the class.

> [!NOTE]
> **Design Evolution**: If a Figma design has changed since the last sync, set `Status: outdated` in the `@Source` line of the affected widget's doc-comment.

## 6. Verify

```bash
melos run generate
melos run analyze
```

If you changed the visuals of an `app_ui` widget, update its goldens per the [Flutter Golden Testing Skill](../flutter-golden-testing/SKILL.md).
