# Alchemist setup (once per package)

## `<package>/test/flutter_test_config.dart`
Runs before every test file in the package. Keep CI goldens (obscured text, platform-agnostic) always on; render readable platform goldens only locally.

Set the app theme here: `goldenTest` has no `theme:` parameter, and without the `app_ui` theme extensions `context.$.colors` throws. Build it the same way `packages/app_ui/test/helpers.dart` does.

```dart
import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:app_ui/app_ui.dart' as ui;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final isCi = Platform.environment.containsKey('CI');
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: const ui.AppThemeLight(ui.TextThemeNative()).themeData,
      platformGoldensConfig: PlatformGoldensConfig(enabled: !isCi),
    ),
    run: testMain,
  );
}
```

For a dark variant of one test, wrap it in `AlchemistConfig.runWithConfig(config: AlchemistConfig.current().copyWith(theme: const ui.AppThemeDark(ui.TextThemeNative()).themeData), run: …)`.

If the file already exists (the app's root `test/flutter_test_config.dart` registers mappers), never replace it: keep its setup calls first, then wrap only `testMain` in `AlchemistConfig.runWithConfig`:

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  registerMappers();
  final isCi = Platform.environment.containsKey('CI');
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(/* theme + platformGoldensConfig as above */),
    run: testMain,
  );
}
```

## Output layout
Alchemist creates these folders itself; don't create them by hand.

- CI goldens: `goldens/ci/<name>.png` next to the test — commit these.
- Platform goldens: `goldens/<platform>/<name>.png` — local reference only, do not commit.
- Failure diffs: `failures/` — never commit.

## `.gitignore` (root)
Keep the existing `**/failures/` entry. To keep platform goldens out of git, add:

```gitignore
**/goldens/**/*.*
!**/goldens/ci/*.*
```
