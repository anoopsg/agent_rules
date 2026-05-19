---
name: bootstrap-project
description: >-
  Detect and resolve missing first-time setup (alchemist, mocktail,
  fake_async, flutter_test_config.dart, CI workflows) in a single
  batched operation. Use on the first task in a project that has
  agent_rules installed but is missing any of the expected dev
  dependencies or config files.
---
# Bootstrap Project Skill

This skill is the safety net for the zero-touch promise of
`agentx --bootstrap`. If the consumer ran `agentx -A -e -B .` with
`--no-auto-deps`, or if they cloned a project that already had agent_rules
but never ran the bootstrap, this skill resolves the gap on the first
relevant task without forcing the user to learn the dep list.

## 1. When to Apply

Run this skill BEFORE the user's first task that touches:
- A widget, view, layout, or theme (golden testing needs `alchemist`).
- A notifier, repository, client, or model (unit testing needs
  `mocktail` and often `fake_async`).
- Any `.dart` file under `lib/` if `pubspec.yaml` is missing the
  expected dev dependencies.

The skill is a no-op if everything is already in place. It is safe to
run on every "first" task; idempotent.

## 2. Detection (Run These Checks Silently)

Before doing anything visible, gather the project state:

1. **`pubspec.yaml` exists?** If no, this is not a Flutter project;
   exit the skill silently.
2. **`alchemist` in dev_dependencies?**
   ```bash
   grep -qE '^[[:space:]]*alchemist:' pubspec.yaml
   ```
3. **`mocktail` in dev_dependencies?**
   ```bash
   grep -qE '^[[:space:]]*mocktail:' pubspec.yaml
   ```
4. **`fake_async` in dev_dependencies?**
   ```bash
   grep -qE '^[[:space:]]*fake_async:' pubspec.yaml
   ```
5. **`test/flutter_test_config.dart` exists?**
6. **`.github/workflows/tests.yml` exists?**
7. **`.github/workflows/goldens.yml` exists?**
8. **`AGENTS.md` exists?**
9. **`BOOTSTRAP.sh` exists in project root?** If yes, prefer running it
   over manual `flutter pub add`.

## 3. Single Batched Approval

If anything is missing, present ONE consolidated approval to the user.
Do not ask piecemeal. Sample message:

> First-time bootstrap detected. To enable the testing and golden
> workflows mandated by the active rules, I need to:
>
> - Add dev dependencies: `alchemist`, `mocktail`, `fake_async`
> - Create `test/flutter_test_config.dart` (golden determinism)
> - Add `.github/workflows/{tests,goldens}.yml` (CI enforcement)
>
> May I proceed? After this one approval, the project will be fully
> set up and no further setup prompts will appear.

If the user declines, halt the original task and explain that the
testability and golden rules cannot be satisfied without the setup.
Do not try to work around it; this is the foundation.

## 4. Execution

After approval, run in this order:

1. **If `BOOTSTRAP.sh` exists, prefer it:**
   ```bash
   bash BOOTSTRAP.sh
   ```
   This is the authoritative dep list maintained by agentx.

2. **Otherwise, install deps directly:**
   ```bash
   flutter pub add --dev alchemist mocktail fake_async
   ```

3. **Emit missing static files** by running:
   ```bash
   agentx -B --no-auto-deps .
   ```
   This re-emits `test/flutter_test_config.dart`, the workflows, and
   `AGENTS.md` with skip-if-exists semantics.

4. **Verify** the install succeeded:
   ```bash
   flutter pub get
   flutter test --no-pub --plain-name "__bootstrap_smoke__" 2>/dev/null || true
   ```

## 5. Verification Loop

After running step 4, re-run section 2 detection. If any check still
fails, surface the specific failure and halt; do not silently continue
into the user's original task with an incomplete environment.

## 6. Disclosure

Report bootstrap completion in the turn summary as the FIRST line,
before the original task's disclosure:

```
bootstrap: alchemist mocktail fake_async added; flutter_test_config.dart
           and CI workflows emitted.
tests: 8 green, 8 added
goldens: 7 green, 7 added
```

If bootstrap was a no-op (everything already in place), do not mention
it in the summary; proceed directly to the original task.

## 7. Pre-Task Self-Check

Before starting any first-relevant-task, answer:

1. Did I run section 2 detection?
2. If anything was missing, did I batch all setup into ONE approval?
3. After approval, did section 5 verification pass?
4. Did I include the bootstrap disclosure line in the turn summary?

If any answer is "no" or "unknown", complete the bootstrap before
touching the user's original task. Mixing setup with feature work
makes diffs unreviewable.
