---
name: create-package
description: >
  Use when adding a new local package to the Dart pub workspace (alongside
  app_ui and framework), e.g. to isolate a new library, plugin wrapper set,
  or shared domain logic. Covers pubspec setup, workspace registration, and
  melos wiring.
---

# Package Creation Skill

This skill defines the process for adding a new local package to the root
Dart pub **workspace**, following the pattern established by
`packages/app_ui` (UI kit) and `packages/framework` (foundation utilities).

## 1. When to Create a Package vs. a Feature/Infrastructure Domain

Create a new workspace package only when the code is genuinely reusable
outside the app itself, or needs a hard dependency boundary (e.g. it must
not depend on Flutter, or must not depend on other app code). If the code
is app-specific business logic, use `create-feature` or
`create-infrastructure` instead — most new work belongs in `lib/src/`, not
a new package.

## 2. Directory Structure

```text
packages/<name>/
├── lib/
│   ├── <name>.dart          # Public barrel — only export what's public API
│   └── src/
│       └── ...              # Implementation, not exported directly
├── test/
│   └── ...                  # Mirrors lib/src/
├── analysis_options.yaml
└── pubspec.yaml
```

- Package name: `snake_case`, matching the directory name.
- Never import a package's `src/` internals from outside the package —
  only the barrel file is the public contract.

## 3. `pubspec.yaml`

Use `resolution: workspace` (not a version constraint on the SDK
environment beyond what the app requires) so the package resolves against
the root workspace's single lockfile:

```yaml
name: <name>
description: "<One-line description>"
version: 0.0.1
publish_to: 'none'

environment:
  sdk: ^3.12.0
  flutter: ">=3.44.0"

resolution: workspace

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  very_good_analysis: ^10.2.0
```

- Only add `flutter:` as a dependency if the package actually needs
  Flutter (widgets, `Color`, etc.). A pure-Dart package (like a data
  model or algorithm library) should omit it to keep the dependency
  surface minimal — `framework` includes it today only because
  `ScaleBinding`/`ViewProps` need Flutter types; don't treat that as a
  requirement.
- If the package needs codegen (`build_runner` + a generator such as
  `riverpod_generator`, `dart_mappable_builder`, or `chopper_generator`),
  add both as `dev_dependencies` — `melos run generate` already targets
  every package via `packageFilters: dependsOn: build_runner`, so no
  script changes are needed.
- **Never** add a dependency on another local package (`app_ui`,
  `framework`, or the root app) unless it is a deliberate, one-directional
  layering decision — `app_ui` and `framework` do not depend on each
  other today.

## 4. `analysis_options.yaml`

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "build/**"
    - "**/*.g.dart"
    - "**/*.mocks.dart"
```

Use `very_good_analysis` for consistency with the root app and `app_ui`
unless the package has a specific reason to diverge (`framework` uses
`flutter_lints` instead — that's a pre-existing exception, not the
pattern to copy).

## 5. Register the Package in the Root Workspace

In the root `pubspec.yaml`:

1. Add the package path to the `workspace:` list:
   ```yaml
   workspace:
     - packages/app_ui
     - packages/framework
     - packages/<name>
   ```
2. If the root app (or another package) will import it, add it as a path
   dependency:
   ```yaml
   dependencies:
     <name>:
       path: packages/<name>
   ```

## 6. Bootstrap and Verify

```bash
melos bootstrap        # or: flutter pub get (at root)
melos run analyze
melos run generate     # only if the package uses build_runner
melos run coverage     # only if test/ exists
```

`melos run coverage` and `melos run generate` already scope to every
workspace package via `packageFilters`, so a new package with a `test/`
directory or a `build_runner` dependency is picked up automatically — no
melos script edits required.

## 7. Barrel File

Export only the intended public API:

```dart
// lib/<name>.dart
export 'src/my_thing.dart';
```

Consumers then import as `import 'package:<name>/<name>.dart';` — never
`package:<name>/src/...`.
