---
name: create-test
description: >
  Process for creating unit and widget tests in the test/ directory
  mirroring the lib/src/ directory structure. Covers using Mockito.
---

# Testing Skill

This skill defines the process for writing and running unit and widget
tests in the project.

## 1. Directory Structure

Test files must mirror the `lib/src/` directory hierarchy under `test/`:

```text
lib/src/
└── infrastructure/
    └── auth/
        └── auth_repository.dart

test/src/
└── infrastructure/
    └── auth/
        └── auth_repository_test.dart
```

All test files must end with the `_test.dart` suffix.

## 2. Mocking Guidelines

- **Mocking Tool**: Use the `mockito` package for mocking infrastructure and
  external client dependencies.
- **Generator**: Annotate test files with `@GenerateMocks` to auto-generate mocks
  using `build_runner`.

### 2.1 Generating Mocks Example

Annotate your test file's `main()` method with the dependencies to mock:

```dart
import 'package:apple_project/src/infrastructure/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import the generated mock file (ends with .mocks.dart)
import 'auth_repository_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  // Test code goes here
}
```

To build/generate the mock implementation, run:

```bash
melos run generate
```

## 3. Writing Unit Tests

Structure tests logically using `group`, `test`, and standard Mockito APIs:

```dart
void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  group('AuthRepository Tests', () {
    test('login returns success on correct credentials', () async {
      // Arrange
      when(mockAuthRepo.login('user', 'pass'))
          .thenAnswer((_) async => const Ok(null));

      // Act
      final result = await mockAuthRepo.login('user', 'pass');

      // Assert
      expect(result.isOk, isTrue);
      verify(mockAuthRepo.login('user', 'pass')).called(1);
    });
  });
}
```

## 4. Running Tests

- Run all unit and widget tests:
  ```bash
  flutter test
  ```
- Run tests for a specific test file:
  ```bash
  flutter test test/src/infrastructure/auth/auth_repository_test.dart
  ```
