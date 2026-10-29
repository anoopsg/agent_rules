---
name: create-infrastructure
description: Creates a feature's data layer (models, API services, repositories) using dart_mappable for models, Chopper for networking, and Riverpod for repositories. Use when the user asks to create a repository, API service, data model, or set up new infrastructure components.
---

# Infrastructure Creation Skill

This skill defines the process for creating a feature's data layer,
covering models, networking, and repositories. Shared low-level clients
live in `lib/src/infrastructure/` (see the create-client skill).

## 1. Directory Structure

Each feature owns its data layer inside `lib/src/features/`. A flat
feature (e.g. `settings`) uses `data/`; a feature group with sub-features
(e.g. `auth`) uses `_self/data/`:

```text
lib/src/features/my_domain/data/   # or my_domain/_self/data/ for a group
├── models/             # DTOs and Domain Models
│   └── user_model.dart # Uses dart_mappable
├── services/           # Remote API definitions (Chopper)
│   └── my_service.dart
├── mocks/              # Optional mock data (see provide-mock-data)
├── my_repository.dart  # Business logic interface
└── data.dart           # Barrel file
```

Export `data.dart` from the feature barrel (e.g. `my_domain.dart`).

## 2. Data Modeling (dart_mappable)

Always use `@MappableClass()` for models to get built-in JSON conversion 
and equality. Models must be **immutable**.

```dart
@MappableClass()
class const UserProfile({
  required final String id,
  required final String email,
}) with UserProfileMappable;
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
Add the service to `apiClient` in `lib/src/infrastructure/network/api_client.dart`:
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

- **Rule**: The data layer must not import its feature's `state/` or `view/`.
  `src/infrastructure/` must not import feature code, except `api_client.dart`
  registering services.
- **Pattern**: Return `Result<T, Failure>` for operations that can fail.

### 4.1 Define Error Codes & Failures
Errors are centralized. You must define a technical code and its translation.

1. **Register the Code** in `lib/src/infrastructure/error_codes.dart`:
```dart
enum AppErrorCode(@override final String value) implements ErrorCode {
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
final class const MyApiFailure({super.error}) extends Failure {
  this : super(code: AppErrorCode.myFeature404);
}
```

### 4.2 Implementation
```dart
class MyRepository({required final MyService _service}) {
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
await storage.save(AppKeys.settings, 'value');
```
