---
name: create-package
description: Adds a new local package to the Dart pub workspace (alongside app_ui and framework) — pubspec, analysis options, workspace and melos wiring. Use when isolating a reusable library or plugin set into its own package. App-specific code stays in lib/src (create-feature).
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

API transport code and DTOs never go in a package: they stay in the app's
API adapter (`lib/src/infrastructure/api/adapters/`).

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

environment:            # copy from the root pubspec.yaml
  sdk: <same as root>
  flutter: <same as root>

resolution: workspace

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  very_good_analysis: ^11.0.0  # match the version in existing pubspecs
```

- Only add `flutter:` as a dependency if the package actually needs
  Flutter (widgets, `Color`, etc.). A pure-Dart package (like a data
  model or algorithm library) should omit it (and use `test` instead of
  `flutter_test`) to keep the dependency
  surface minimal — `framework` includes it today only because
  `ScaleBinding`/`ViewProps` need Flutter types; don't treat that as a
  requirement.
- If it needs Material widgets, depend on `material_ui` and import
  `package:material_ui/material_ui.dart` (as `app_ui` does), not
  `package:flutter/material.dart`.
- If the package needs codegen (`build_runner` + a generator such as
  `riverpod_generator`, `dart_mappable_builder`, or `flutter_gen_runner`),
  add both as `dev_dependencies` — `melos run generate` already targets
  every package via `packageFilters: dependsOn: build_runner`, so no
  script changes are needed.
- **Never** add a dependency on another local package (`app_ui`,
  `framework`, or the root app) unless it is a deliberate, one-directional
  layering decision — `app_ui` and `framework` do not depend on each
  other today.
- The app registers only its own `dart_mappable` mappers
  (`lib/src/_bootstrap/mappers.dart`). If the app decodes the package's
  `@MappableClass` types generically, the package must export its own
  mapper initializer (`@MappableLib(generateInitializerForScope:
  InitializerScope.package)`) and the app must call it at startup next to
  `registerMappers()`.

## 4. `analysis_options.yaml`

Copy `packages/app_ui/analysis_options.yaml`:

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "build/**"
    - "**/*.g.dart"
    - "**/*.mocks.dart"

linter:
  rules:
    use_declaring_parameters: true
```

Use `very_good_analysis` for consistency with the root app and `app_ui`
unless the package has a specific reason to diverge. Don't copy
`framework`'s file: it lacks the generated-file excludes.

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
