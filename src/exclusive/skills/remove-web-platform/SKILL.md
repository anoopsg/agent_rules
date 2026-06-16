---
name: remove-web-platform
description: >
  Use when completely removing the web platform from the project. Details how
  to delete directories/configurations, clean up app_ui web components, remove
  web-specific feature views (*_view_web.dart), prune conditional imports/logic,
  and run validation.
---

# Remove Platform Skill

This skill defines the process for completely removing all files, configurations,
and dead code associated with the web platform from the codebase when restricted
to mobile (Android/iOS) only.

## 1. Delete Web and Deployment Files

Delete the `web/` directory and any web-only deployment/configurations from the
project root:

- Delete the web platform folder:
  `web/`
- Delete the web deployment configurations (e.g., `Dockerfile`, `nginx.conf`).

## 2. Clean Up Web Dependencies

Remove web-only plugins or packages from the dependencies list in the root
[pubspec.yaml](file:///Users/anoopsg/Documents/Development/OSS/launchpad/build/prototype/pubspec.yaml):

1. Open `pubspec.yaml`.
2. Delete the `flutter_web_plugins` dependency:
   ```diff
   -  flutter_web_plugins:
   -    sdk: flutter
   ```
3. Run melos package bootstrap:
   ```bash
   melos bootstrap
   ```

## 3. Delete app_ui Web Components

Delete the web-specific design and styling components in `packages/app_ui`:

- Delete the web-specific exports file (e.g., `packages/app_ui/lib/app_ui_web.dart`).
- Delete the web-specific widgets directory (e.g., `packages/app_ui/lib/src/widgets/web/`).

## 4. Clean Up Bootstrap Files

Remove web-specific initializers in `lib/src/_bootstrap/` (or equivalent setup):

1. Delete any `_web.dart` bootstrap files.
2. Remove HTML conditional imports from the main bootstrap file:
   ```diff
   -import 'package:my_app/.../_stub.dart'
   -    if (dart.library.html) '_web.dart'
   -    if (dart.library.io) '_native.dart'
   -    as lib;
   +import 'package:my_app/.../_stub.dart'
   +    if (dart.library.io) '_native.dart'
   +    as lib;
   ```

## 5. Scan and Delete Web View Files

In features, web views typically follow a naming convention like `*_view_web.dart`,
while mobile views use `*_view.dart`. Scan the `lib/` directory for any files
matching `*_view_web.dart` and delete them.

## 6. Clean Up Page and Routing References

Remove imports and references to the deleted web views inside the corresponding
parent pages:

1. Remove the import lines for `*_view_web.dart` files.
2. Simplify conditional instantiation of the view, using the mobile view only:
   ```diff
   -return kIsWeb ? MyViewWeb(props) : MyView(props);
   +return MyView(props);
   ```
3. Remove error delegation or other conditional calls referencing the web view:
   ```diff
   -if (kIsWeb) {
   -  MyViewWeb.delegateError(context, message);
   -} else {
   -  MyView.delegateError(context, message);
   -}
   +MyView.delegateError(context, message);
   ```

## 7. Thoroughly Prune kIsWeb Conditional Logic

Search the codebase for `kIsWeb` and prune the conditional branches:

- **Router**: Remove web-only routes and checks in routing configurations.
  ```diff
  -initialLocation: kIsWeb ? WebRoute.path : MobileRoute.path,
  +initialLocation: MobileRoute.path,
  ```
- **State Notifiers**: Inside state managers, unconditionally execute the
  mobile flows.
  ```diff
  -if (!kIsWeb) _listenToUpdate();
  +_listenToUpdate();
  ```
- **UI Packages**: Search `packages/app_ui` for `kIsWeb` usages and remove the
  web-specific logic.

## 8. Clean Up Firebase Configurations

If Firebase is configured, remove web guards in the initialization flow:

- In Firebase setup files, remove return guards:
  ```diff
  -if (kIsWeb) return;
  ```
## 9. Verification and Re-generation

After cleanups, run code generation and static analysis to ensure all broken
references are resolved:

```bash
# Re-generate code models/riverpod providers
melos run generate

# Run static analysis
melos run analyze
```
