---
name: prevent-hallucination
description: >-
  Verify symbols, imports, packages, and file paths against real source
  before referencing them. Use whenever about to write a new import,
  add a dependency, call an unfamiliar API, or assert how code behaves.
---
# Prevent Hallucination Skill

This skill defines the verification workflow used to keep generated code
grounded in real symbols, imports, packages, and paths. Apply it whenever
you are about to reference something you did not write in the current
session.

## 1. When to Apply

Run the checklist before:
- Writing any `import` not already present in the target file.
- Calling any class, method, constant, or extension from another module
  or package.
- Adding or upgrading a dependency in `pubspec.yaml`.
- Referencing a file path, asset, or named route.
- Asserting how an existing API behaves (return values, error modes,
  side effects).

## 2. Verification Checklist

Run checks in order. Skip a step only if a prior step proves the fact.
Stop and ask the user if any check fails.

### 2.1 Symbol Exists
1. Search the codebase first:
   ```text
   grep_search "class MyService"
   grep_search "MyService.create"
   ```
2. Open the source with `view_file` to confirm signature, visibility,
   and intended usage.
3. If not found locally, look in the package's docs on pub.dev — but
   only for packages already declared in `pubspec.yaml`.

### 2.2 Import Path Resolves
1. Confirm the file exists under `lib/` (current package) or the
   target package's `lib/`.
2. Prefer the public barrel (e.g., `package:app_ui/app_ui.dart`) when
   one exists. Avoid deep imports.
3. Never invent relative paths — verify with `view_file` first.

### 2.3 Package & Version Exists
1. Look up the package in `pubspec.yaml` and `pubspec.lock`.
2. If absent, do NOT add it silently — ask the user first.
3. When approved, use the latest stable version from pub.dev. Never
   invent or guess version numbers.

### 2.4 Signature & Behavior
1. Read the function/class definition before calling it.
2. Copy positional/named parameters from source — don't guess defaults
   or nullability.
3. If behavior is undocumented, mark assumptions explicitly:
   > Assuming `getProfile()` returns `null` on 404 — verify in source.

### 2.5 File / Path Exists
1. Use `list_dir` or `view_file` before referencing any path.
2. Asset paths: confirm the file exists in the assets directory and
   regenerate the assets class (e.g., `melos run generate`) if needed.

## 3. Citation Format

When stating a fact about the codebase in chat, cite the source:

```text
`MyService.create` is defined at
`lib/src/infrastructure/my/services/my_service.dart:12`.
```

In tool inputs, prefer `@filename` references. Do not put citations
in code comments.

## 4. Honesty Protocol

- If a verification step fails, say **"unverified"** in the response.
- Never fabricate plausible-looking code to fill a gap.
- Prefer a targeted question over a confident guess.
- If the user insists on speed, mark the unverified line with a
  `// TODO(verify): ...` comment and surface it in the turn summary.

## 5. Examples

### 5.1 Good — Verified Reference
```dart
// Verified at lib/src/infrastructure/auth/auth.dart:8
import 'package:myapp/src/infrastructure/auth/auth.dart';

final repo = ref.watch(authRepositoryProvider);
```

### 5.2 Bad — Hallucinated Reference
```dart
import 'package:myapp/auth/auth.dart';
final user = ref.watch(authProvider).currentUser;
```
Why it's bad: path not verified, `authProvider` has no grep evidence,
and `currentUser` signature was guessed.

## 6. Pre-Response Self-Check

Before sending the final response or diff, answer:
1. Does every imported symbol exist? (grep evidence)
2. Does every called method match the source signature?
3. Did I add any package without asking?
4. Did I cite a path I have no evidence for?
5. If I touched any widget, view, layout, or theme: did I follow the
   [golden-sandbox](../golden-sandbox/SKILL.md) loop and include its
   §5.6 disclosure in the turn summary? UI behavior is verified by
   goldens, not asserted.
6. If I added or modified any production code under `lib/`: did I
   follow the [testable-code](../testable-code/SKILL.md) loop, ship
   the matching tests, and include its §6.5 disclosure? Behavior
   claims are verified by tests, not asserted.

If any answer is "no" or "unknown", revise before responding.
