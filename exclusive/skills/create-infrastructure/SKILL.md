---
name: create-infrastructure
description: >-
  Create a new domain in lib/src/infrastructure/ with dart_mappable
  models, Chopper services, repositories returning Result<T, Failure>,
  and Riverpod wiring. Use when adding a new backend integration,
  persisted domain, or API surface.
---
# Infrastructure Creation Skill

This skill defines the process for creating a new domain in the 
`infrastructure/` layer, covering models, networking, and repositories.

## 1. Directory Structure

Infrastructure is organized by domain in `lib/src/infrastructure/`:

```text
lib/src/infrastructure/my_domain/
├── models/             # DTOs and Domain Models
│   └── user_model.dart # Uses dart_mappable
├── services/           # Remote API definitions (Chopper)
│   └── my_service.dart
├── my_repository.dart  # Business logic interface
└── my_domain.dart      # Barrel file
```

## 2. Data Modeling (dart_mappable)

Always use `@MappableClass()` for models to get built-in JSON conversion 
and equality. Models must be **immutable**.

```dart
@MappableClass()
class UserProfile with UserProfileMappable {
  const UserProfile({
    required this.id,
    required this.email,
  });

  final String id;
  final String email;
}
```

## 3. Networking (Chopper)

Define API services as abstract classes extending `ChopperService`. Use 
`apiClient` to consume them.

### 3.1 Define the Service
```dart
@ChopperApi()
abstract class MyService extends ChopperService {
  static MyService create([ChopperClient? client]) => _$MyService(client);

  @GET(path: '/profile')
  Future<Response<UserProfile>> getProfile();
}
```

### 3.2 Register the Service
Add the service to `apiClient` in `lib/src/infrastructure/_clients/api_client.dart`:
```dart
@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  return ApiClient(
    services: [
      MyService.create(), // Register here
    ],
  );
}
```

## 4. Repositories

Repositories bridge the gap between clients (API, Storage) and the Features.

- **Rule**: NEVER import from `src/features/` into `src/infrastructure/`.
- **Pattern**: Return `Result<T, Failure>` for operations that can fail.

### 4.1 Define Error Codes & Failures
Errors are centralized. You must define a technical code and its translation.

1. **Register the Code** in `lib/src/infrastructure/error_codes.dart`:
```dart
enum AppErrorCode implements ErrorCode {
  myFeature404('myFeature404'), // Key in i18n
  // ...
}
```

2. **Add Translations** under the `errors` key in `lib/i18n/*.i18n.json` 
for ALL locales:

```json
// en.i18n.json
"errors": {
  "myFeature404": "The requested resource was not found."
}

// ar.i18n.json
"errors": {
  "myFeature404": "لم يتم العثور على المورد المطلوب."
}
```

3. **Generate Translations**:
Run the following command to sync the JSON changes with the Dart code:
```bash
melos run translate
```

4. **Define the Failure**:
```dart
final class MyApiFailure extends Failure {
  const MyApiFailure({super.error}) : super(code: AppErrorCode.myFeature404);
}
```

### 4.2 Implementation
```dart
class MyRepository {
  MyRepository({required MyService service}) : _service = service;
  final MyService _service;

  Future<Result<UserProfile, Failure>> getProfile() async {
    try {
      final response = await _service.getProfile();
      if (response.isSuccessful) return Ok(response.body!);
      return Err(MyApiFailure(error: response.error));
    } catch (e) {
      return Err(MyApiFailure(error: e));
    }
  }
}
```

## 5. Riverpod Integration

Provide the repository via a global provider. Obtain the required service 
from the `apiClientProvider`.

```dart
@Riverpod(keepAlive: true)
MyRepository myRepository(Ref ref) {
  final service = ref.watch(apiClientProvider).getService<MyService>();
  return MyRepository(service: service);
}
```

## 6. Persistence

Use `StorageClient` for general persistence or `SecureStorageClient` for 
sensitive data (tokens). Always use **`AppKeys`** for storage keys.

```dart
final storage = ref.watch(storageClientProvider);
await storage.write(AppKeys.settings, 'value');
```

## 7. Tests (Mandatory)

Per the [testable-code](../../../skills/testable-code/SKILL.md) skill,
every infrastructure domain ships with three test files in the same change:

- **Repository unit test** at `test/infrastructure/<d>/<d>_repository_test.dart`.
  Mock the service. Cover success → `Ok`, network error → `Err(<NetworkFailure>)`,
  parse error → `Err(<ParseFailure>)`, and each domain-specific failure code
  registered in `error_codes.dart`.
- **Service test** at `test/infrastructure/<d>/services/<s>_test.dart`.
  Use a `MockClient` from `http`. Assert request method, path, headers,
  and response body parsing.
- **Model test** at `test/infrastructure/<d>/models/<m>_test.dart`.
  Round-trip JSON via `dart_mappable` and assert equality across
  `copyWith` mutations.

Run `flutter test` and include the `tests:` disclosure line per
[core/testability.md](../../../rules/core/testability.md) before
reporting the task complete.
