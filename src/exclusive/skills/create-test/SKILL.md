---
name: create-test
description: Writes unit, repository, notifier and widget tests with mockito, mirroring lib/src/ in test/src/. Use when adding or fixing tests or raising coverage. For screenshot tests use flutter-golden-testing.
---

# Testing Skill

This skill defines the process for writing and running unit and widget
tests in the project.

## 1. Directory Structure

Test files must mirror the `lib/src/` directory hierarchy under `test/`:

```text
lib/src/
└── features/
    └── auth/
        └── _self/
            └── data/
                └── auth_repository.dart

test/src/
└── features/
    └── auth/
        └── _self/
            └── data/
                └── auth_repository_test.dart
```

All test files must end with the `_test.dart` suffix. Internal packages have
their own `test/` folder (e.g. `packages/app_ui/test/`).

### 1.1 Test Configuration
`test/flutter_test_config.dart` runs before every app test and registers the
`dart_mappable` mappers, as the app does at startup. Never register mappers
inside a test, and never replace this file — extend it (e.g. for Alchemist,
see the `flutter-golden-testing` skill).

## 2. Mocking Guidelines

- **Mocking Tool**: Use the `mockito` package for mocking repositories and
  external client dependencies.
- **Generator**: Annotate test files with `@GenerateMocks` to auto-generate mocks
  using `build_runner`.
- **Mock Dependencies, Not the Subject**: List the dependencies of the class
  under test (e.g. `ApiClient` for a repository, the repository for a
  notifier), never the class itself.

### 2.1 Generating Mocks Example

Annotate your test file's `main()` method with the dependencies to mock.
A repository test mocks the single `ApiClient` (in
`lib/src/infrastructure/api/`), which returns feature models as `Result`.
Mockito can't build a `Result` on its own, so register a dummy for each
`Result` type the mock returns:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:framework/framework.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:<project_name>/src/features/features.dart';
import 'package:<project_name>/src/infrastructure/infrastructure.dart';

// Import the generated mock file (ends with .mocks.dart)
import 'notifications_repository_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  provideDummy<Result<int, Failure>>(const Ok(0));

  // Test code goes here
}
```

To build/generate the mock implementation, run:

```bash
melos run generate
```

Never hand-edit the generated `.mocks.dart` file. Re-run the command after
adding or changing an `ApiClient` method, or the mock goes stale.

## 3. Writing Unit Tests

Structure tests logically using `group`, `test`, and standard Mockito APIs:

```dart
@GenerateMocks([ApiClient])
void main() {
  provideDummy<Result<int, Failure>>(const Ok(0));

  late MockApiClient api;
  late NotificationsRepository repository;

  setUp(() {
    api = MockApiClient();
    repository = NotificationsRepository(api: api);
  });

  group('NotificationsRepository', () {
    test('getUnreadCount returns the API result', () async {
      // Arrange
      when(api.getUnreadCount()).thenAnswer((_) async => const Ok(3));

      // Act
      final result = await repository.getUnreadCount();

      // Assert
      expect((result as Ok<int, Failure>).data, 3);
      verify(api.getUnreadCount()).called(1);
    });
  });
}
```

### 3.1 What Each Layer Tests
- **Repository**: Stub `ApiClient` with `Ok`/`Err` and assert what the
  repository adds (paging defaults, persistence, mapping). Errors arrive as
  `ApiFailure`; just check they pass through.
- **API adapter**: HTTP status and transport errors are tested **once**, in
  the adapter tests under `test/src/infrastructure/api/adapters/openapi/`,
  using `OpenApiClient(httpClient: MockHttpClient(...))` — never again in
  repository tests (`grep -rl "MockHttpClient(" test/src/infrastructure`).
- **Notifier**: Mock its repository and use `ProviderContainer(overrides: [...])`
  with `addTearDown(container.dispose)` (`grep -rl "ProviderContainer(" test/src/features`).
- **`app_ui` widget**: Pump through `pumpThemed` (`packages/app_ui/test/helpers.dart`)
  so `context.$` resolves. For visual regression, see the `flutter-golden-testing` skill.

## 4. Running Tests

- Run all unit and widget tests:
  ```bash
  flutter test
  ```
- Run tests for a specific test file:
  ```bash
  flutter test test/src/features/auth/_self/data/auth_repository_test.dart
  ```
- Run the tests of every package (app and `packages/*`) with coverage:
  ```bash
  melos run coverage
  ```
