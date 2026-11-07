---
name: add-config-flag
description: Adds a compile-time switch — a FeatureFlags toggle or an Environment dart-define set in env/*.json. Use when turning app behavior on or off, or adding a per-flavor value such as a base URL, API key or mock switch.
---

# Config Flag Skill

This skill defines the process for adding a compile-time switch, so that "is
this on, and what is it set to?" is always a one-file answer.

## 1. Pick the Kind

| Need | Kind | Lives in |
|---|---|---|
| A product toggle, the same for every flavor | `FeatureFlags` constant | `lib/src/system/feature_flags.dart` |
| A value that differs per flavor, or a secret (URL, key, mock switch) | `Environment` define | `lib/src/system/environment.dart` |

Both are compile-time constants: changing one means rebuilding the app. There is
no runtime or remote config; **stop and ask** if the user needs a value that
changes without a release.

## 2. Add a Feature Flag

1. Add `static const bool <name>Enabled = <default>;` to `FeatureFlags`, with a
   doc comment. Name it as a statement (`onboardingEnabled`, not `onboarding`).
2. Read it at the **single point that owns the behavior** (a repository getter,
   a guard or one widget), never in several features, so its effect stays in one
   place. See how existing flags are read: `grep -rn "FeatureFlags\." lib/src/features`.
3. If `docs/architecture/feature-flags.md` exists, add the flag and its effect
   when `false` to its table.

## 3. Add an Environment Define

1. Add `static const <Type> <name> = <Type>.fromEnvironment('<KEY>');` to
   `Environment`, with a doc comment (`String`, `bool` or `int`). Read it only as
   `Environment.<name>`, never by calling `fromEnvironment` elsewhere. Existing
   defines: `grep -n "fromEnvironment" lib/src/system/environment.dart`.
2. Make the default (key missing) **safe for a release build**: off, empty or
   production. A build that forgets the key must not ship test data or crash.
3. Add the key to `env/sample.json`, the committed template, with a placeholder,
   never a real secret. Add it to your local per-flavor env files too (they are
   gitignored).

## 4. Testing

A `const` can't be changed from a test. Either write the expectation in terms of
the flag, so it holds whichever way it is set
(`expect(result, !FeatureFlags.<name>Enabled)`), or inject the value into the
class that owns the behavior and test both values.

## 5. Verify

Run the app with a flavor's defines. Its entry point and env file are in
`.vscode/launch.json` (or `docs/getting-started/` if present). Then run:

```bash
melos run analyze
melos run coverage
```
