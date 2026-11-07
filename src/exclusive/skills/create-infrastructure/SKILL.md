---
name: create-infrastructure
description: Creates a feature's data layer — dart_mappable models, Riverpod repositories over ApiClient or storage, failures and persistence. Use when adding a model, repository or local persistence to a feature. New endpoints — add-api-endpoint; plugin wrappers — create-client.
---

# Infrastructure Creation Skill

This skill defines the process for creating a feature's data layer,
covering models, repositories, and persistence. Backend calls go through
the shared `ApiClient` (see the add-api-endpoint skill). Shared low-level
clients live in `lib/src/infrastructure/` (see the create-client skill).

## 1. Directory Structure

Each feature owns its data layer inside `lib/src/features/`. A flat
feature (e.g. `settings`) uses `data/`; a feature group with sub-features
(e.g. `auth`) uses `_self/data/`:

```text
lib/src/features/my_domain/data/   # or my_domain/_self/data/ for a group
├── models/             # Domain Models, shaped for the app
│   └── user_profile.dart # Uses dart_mappable (no `_model` suffix)
├── my_repository.dart  # Business logic interface
└── data.dart           # Barrel file
```

Export `data.dart` from the feature barrel (e.g. `my_domain.dart`).

A feature has no `services/`, DTOs or `mocks/`. Chopper services, DTOs and
mock fixtures live in the API adapter under
`lib/src/infrastructure/api/adapters/openapi/` and are added with the
add-api-endpoint skill. Small helpers the repository needs may sit next to
it (e.g. `session_storage.dart` in `auth/_self/data/`).

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

- **Shape models for the app, not the wire.** JSON keys and API shapes
  belong to the adapter's DTOs, which map to your model with `toModel()`.
- **Mappers register automatically.** `lib/src/_bootstrap/mappers.dart`
  initializes every mapper of the package after `melos run generate`; never
  register them by hand.

## 3. Backend Calls (ApiClient)

The app has one `ApiClient` in `lib/src/infrastructure/api/api_client.dart`.
Each method is named after an operationId in `contracts/openapi.json` and
returns your feature model as a `Result`; the openapi adapter maps its DTOs
and errors to it. Repositories never touch Chopper, `http`, DTOs or mocks.

```dart
abstract interface class ApiClient {
  /// Fetches the current user's profile.
  Future<Result<UserProfile, Failure>> getProfile();
}
```

To add a call the `ApiClient` doesn't have yet (spec, method, adapter
service, DTO and mock fixture), follow the add-api-endpoint skill.

## 4. Repositories

Repositories bridge the gap between clients (API, Storage) and the Features.

- **Rule**: The data layer must not import its feature's `state/` or `view/`.
  Only `lib/src/infrastructure/api/` may import feature code (to return
  feature models); the rest of `src/infrastructure/` must not.
- **Pattern**: Return `Result<T, Failure>` for operations that can fail.

### 4.1 Define Error Codes & Failures
Errors are centralized: every failure carries an `AppErrorCode` with a
translated message.

API errors already arrive as an `ApiFailure` carrying an `AppErrorCode`;
don't wrap them. Define a feature `Failure` only for non-API errors
(storage, parsing, local rules).

1. **Register the Code and its Translations** as described in the
   add-translations skill (§3): add the `AppErrorCode` (with the backend code
   if the API sends one), its message under `errors` in every locale, then
   regenerate.

2. **Define the Failure** (non-API errors only), next to the repository:
```dart
final class const MyCacheFailure({super.error}) extends Failure {
  this : super(code: AppErrorCode.myFeatureCache);
}
```

### 4.2 Implementation
API calls usually pass straight through, since `ApiClient` already returns
a `Result`:
```dart
class MyRepository({required final ApiClient _api}) {
  Future<Result<UserProfile, Failure>> getProfile() => _api.getProfile();
}
```
Add logic only for caching, persistence or combining calls (e.g.
`AuthRepository` also saves the session to secure storage). Public methods
never throw.

## 5. Riverpod Integration

Provide the repository via a global provider. Pass it the `ApiClient`
from `apiClientProvider`.

```dart
@Riverpod(keepAlive: true)
MyRepository myRepository(Ref ref) {
  return MyRepository(api: ref.watch(apiClientProvider));
}
```

## 6. Persistence

Use `StorageClient` for general persistence or `SecureStorageClient` for 
sensitive data (tokens). Always use **`AppKeys`** for storage keys.

```dart
final storage = ref.watch(storageClientProvider);
await storage.save(AppKeys.settings, settings.toMap());
```

Store models with `toMap()` and read them back with `<Model>Mapper.fromMap`
(see `SettingsRepository`).

## 7. Verify

```bash
melos run generate
melos run analyze
```

Repository tests mock `ApiClient` with `Result` dummies (see the
create-test skill).
