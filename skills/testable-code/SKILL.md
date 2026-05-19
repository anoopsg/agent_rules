---
name: testable-code
description: >-
  Generate testable Dart/Flutter code and the accompanying tests in the
  same change. Defines the per-artifact test matrix, mocking and time
  control patterns, run-loop, and turn-summary disclosure. Use whenever
  creating or modifying a notifier, repository, client, model, widget,
  or route.
---
# Testable Code Skill

This skill defines how to generate code that can actually be tested
and how to ship the tests in the same change. It is the unit-, widget-,
and behavior-test counterpart to [golden-sandbox](../golden-sandbox/SKILL.md),
which covers visual regression. Both run before task completion.

## 1. When to Apply

Run the loop in section 6 before reporting the task complete whenever
you have:
- Created or modified a Riverpod notifier or any state class.
- Added or changed a repository, service, or client.
- Added or changed a model that has equality/serialization semantics.
- Added or changed a widget with interactive or branching logic.
- Added or changed a route, redirect, or navigation flow.
- Added or modified a pure utility function or extension.

### 1.1 Drift Cases (Still Required)

These look small and routinely get skipped. They still require tests:
- **"Just a small refactor."** Behavior must remain identical; only
  tests prove that.
- **"Just renamed the variable."** If a public API name changed, every
  caller and its test must follow.
- **"It's just a getter."** Getters with branching or null-safety
  logic still need a test for each branch.
- **"It's a thin wrapper around an SDK call."** That is exactly what
  needs a mock-backed test so the SDK can swap.
- **"The notifier just calls the repository."** Test the call shape,
  the error mapping, and the loading state transitions.

### 1.2 Genuine Skip Cases (Rare)

Tests may be skipped only when ALL of these are true:
- No production source code under `lib/` was added or modified.
- No public API contract changed.
- The change is provably non-behavioral (markdown, doc comments only,
  comments-only refactor, asset relocation that does not change paths
  used in code, generated-file regeneration where the spec did not
  change).

If skipping, the turn summary MUST state the reason in the disclosure
format from section 6.5. Silent skip is a rule violation.

## 2. Testability Principles

The architectural rules in [core/testability.md](../../rules/core/testability.md)
are the contract. This skill expands them.

- **Constructor or `Ref` injection.** Every collaborator (repository,
  client, clock, random, logger) enters via constructor parameter or
  `ref.watch` / `ref.read`. Never reach for a global.
- **Wrap ambient IO.** `DateTime.now()`, `Stopwatch`, `Random`,
  `Platform.isIOS`, `File`, `HttpClient` — all wrapped in clients or
  passed as parameters with safe defaults.
- **One responsibility per class.** Notifier coordinates state;
  repository coordinates data sources; service speaks HTTP; client
  hides a plugin. Crossed responsibilities make tests gymnasts.
- **Avoid `BuildContext` outside widgets.** Notifier methods take
  primitives or `Ref`. View callbacks read from `ref` inside the
  closure (also enforced by the `MemoizedView` stale-closure rule in
  [create-feature](../../exclusive/skills/create-feature/SKILL.md)).
- **Public API doc comments.** Each public method names its inputs,
  outputs, error modes, and edge cases. Tests verify each line.

## 3. Per-Artifact Test Matrix

Every artifact you create or modify must have at least the test types
in the "Required" column.

| Artifact | Required test type | File location | Notes |
| :--- | :--- | :--- | :--- |
| Riverpod notifier | Unit | `test/features/<f>/state/<f>_notifier_test.dart` | Override deps with `ProviderContainer.test`; assert state transitions and error mapping |
| Repository | Unit (mocked services/clients) | `test/infrastructure/<d>/<d>_repository_test.dart` | Verify `Result<T, Failure>` mapping for success, network failure, and parse failure |
| Chopper service | Unit (mocked HTTP) | `test/infrastructure/<d>/services/<s>_test.dart` | Use `MockClient` from `http`; assert request shape and response parsing |
| Client (plugin wrapper) | Unit (mocked plugin) | `test/infrastructure/_clients/<c>_test.dart` | Mock the plugin SDK; assert error swallowing returns the documented sentinel |
| Model (`@MappableClass`) | Unit | `test/infrastructure/<d>/models/<m>_test.dart` | Round-trip JSON; equality across `copyWith` |
| Widget (interactive) | Widget | `test/features/<f>/view/<v>_test.dart` | `pumpWidget`; assert taps invoke callbacks and rebuild semantics |
| Widget (visual) | Golden — see [golden-sandbox](../golden-sandbox/SKILL.md) | `test/goldens/...` | This skill does NOT replace golden coverage |
| Route / redirect | Smoke | `test/routes/<r>_test.dart` | `GoRouter.of(context).goNamed`; assert location after redirect |
| Pure function / extension | Unit | mirror source path under `test/` | One test per branch and one per documented edge case |

## 4. Tooling

Add to `dev_dependencies` in `pubspec.yaml` (ask before adding any new
dependency per [core/communication.md](../../rules/core/communication.md)):

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0       # mocks without code generation
  fake_async: ^1.3.0     # virtual clock for time-dependent tests
  test: ^1.24.0
```

Patterns:
- **Mocks**: `mocktail` over `mockito` — null-safe, no codegen.
  ```dart
  class _MockRepo extends Mock implements UserRepository {}
  ```
- **Time**: wrap time-dependent code in `fake_async`:
  ```dart
  fakeAsync((async) {
    final notifier = container.read(loginNotifierProvider.notifier);
    notifier.startLoginTimeout();
    async.elapse(const Duration(seconds: 30));
    expect(container.read(loginNotifierProvider).status, LoginStatus.timedOut);
  });
  ```
- **Riverpod**: build a `ProviderContainer` per test with overrides:
  ```dart
  final container = ProviderContainer(overrides: [
    userRepositoryProvider.overrideWithValue(mockRepo),
  ]);
  addTearDown(container.dispose);
  ```
- **Random**: inject a seeded `Random` or use a fixed-output fake.
- **Network**: `MockClient` from `http`, or service-level mocks.

## 5. Writing Tests — Concrete Examples

### 5.1 Notifier
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockAuthRepo();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
  });

  test('login emits loading then success on valid credentials', () async {
    when(() => repo.login(any(), any())).thenAnswer(
      (_) async => Ok(const Session(token: 't')),
    );

    final notifier = container.read(loginNotifierProvider.notifier);
    final future = notifier.login('a@b.c', 'pw');

    expect(container.read(loginNotifierProvider).status, LoginStatus.loading);
    await future;
    expect(container.read(loginNotifierProvider).status, LoginStatus.success);
  });

  test('login surfaces failure code on error', () async {
    when(() => repo.login(any(), any())).thenAnswer(
      (_) async => Err(const InvalidCredentialsFailure()),
    );

    final notifier = container.read(loginNotifierProvider.notifier);
    await notifier.login('a@b.c', 'wrong');

    expect(container.read(loginNotifierProvider).errorCode,
           AppErrorCode.authInvalidCredentials);
  });
}
```

### 5.2 Repository
```dart
test('getProfile maps 404 to NotFoundFailure', () async {
  final service = _MockUserService();
  when(() => service.getProfile()).thenAnswer(
    (_) async => Response<UserProfile>(http.Response('', 404), null),
  );

  final repo = UserRepository(service: service);
  final result = await repo.getProfile();

  expect(result, isA<Err<UserProfile, Failure>>());
  expect((result as Err).error, isA<UserNotFoundFailure>());
});
```

### 5.3 Widget
```dart
testWidgets('PrimaryButton invokes onPressed once on tap', (tester) async {
  var taps = 0;
  await tester.pumpWidget(MaterialApp(home: Scaffold(
    body: YzPrimaryButton(label: 'OK', onPressed: () => taps++),
  )));

  await tester.tap(find.byType(YzPrimaryButton));
  await tester.pump();

  expect(taps, 1);
});
```

### 5.4 Route
```dart
testWidgets('redirects unauthenticated user to /login', (tester) async {
  final router = buildRouter(isAuthenticated: () => false);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  router.goNamed('home');
  await tester.pumpAndSettle();
  expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
});
```

## 6. The Loop (Gating Workflow)

Run after every code edit, before reporting complete:

1. **Run the suite.** Use the project command if defined (e.g.
   `melos run test`); otherwise:
   ```bash
   flutter test
   ```
   For a focused run during iteration:
   ```bash
   flutter test test/features/auth/
   ```
2. **On red:** read the failure output. Each failure tells you the
   expected/actual at the assert site.
3. **Classify:**
   - **Regression** — your change broke an existing behavior. Fix the
     code, not the test.
   - **Stale test** — the test asserts an obsolete contract. Update
     the test to match the new spec; document the change in the turn
     summary.
   - **Flaky** — non-deterministic (timing, ordering, real IO). Wrap
     in `fake_async`, replace real IO with a mock, pin the seed.
4. **Re-run** until green.
5. **Disclose in the turn summary.** Use exactly one of these formats:
   - `tests: <N> green, <M> added` — net-new code with new tests.
   - `tests: <N> green, <M> added, <K> updated (<reason>)` — name each
     updated test and why.
   - `tests: skipped because <reason>` — only allowed if the change
     meets section 1.2. State which file changed and why no production
     behavior moved.
6. **Only after disclosure** report the task complete.

## 7. CI Integration

CI is the only enforcement gate that is not a heuristic. Even if the
agent skips the loop, CI catches the gap.

### 7.1 Principles
- Run the full suite on every PR; fail the PR on any red test.
- Pin the Flutter version (`.fvmrc` or workflow input).
- Cache `~/.pub-cache`; do not cache compiled tests.
- Upload a JUnit-style report or test log as an artifact so the agent
  can read failures on the next iteration.

### 7.2 Starter GitHub Actions Workflow

Drop this in `.github/workflows/tests.yml`:

```yaml
name: Tests

on:
  pull_request:
  push:
    branches: [main]

jobs:
  unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x' # pin to project's version
          channel: stable
          cache: true

      - run: flutter pub get

      - name: Run tests
        run: flutter test --machine > test-report.json
        continue-on-error: false

      - name: Upload report on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: test-report
          path: test-report.json
          retention-days: 7
```

For monorepos using melos, replace the test step with the project's
defined task (e.g. `melos run test`).

## 8. Pre-Completion Self-Check

Before producing the final response or marking the task done, answer:

1. Does every artifact I created or modified appear in the matrix
   in section 3, and does it have its required test type?
2. Did I run the full suite (or at least every test in directories I
   touched) and is the output green?
3. If I updated tests, did I name each updated test in the disclosure
   line with a reason?
4. Does my turn summary contain the section 6.5 disclosure line?
5. If I am claiming section 1.2 skip eligibility: did I list the file
   that changed and explain why no production behavior moved?
6. For UI changes specifically: did I also follow [golden-sandbox](../golden-sandbox/SKILL.md)
   for visual coverage? Goldens and behavior tests do not substitute
   for each other.

If any answer is "no" or "unknown", go back to section 6 step 1
before responding. This pairs with the [prevent-hallucination](../prevent-hallucination/SKILL.md)
skill: behavior claims must be verified by tests, not asserted.
