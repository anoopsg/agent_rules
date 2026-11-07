---
name: add-api-endpoint
description: Adds or changes a backend API call end to end — contracts/openapi.json, the ApiClient method, the adapter's DTO, service and mock route, and the repository call. Use when adding an endpoint, syncing openapi.json with a new backend spec, mocking an endpoint before the backend ships, or mapping a backend error code.
---

# Add API Endpoint Skill

This skill defines the process for adding a backend call end to end: from the
spec in `contracts/openapi.json`, through the transport-neutral `ApiClient` and
its REST adapter, to the mock that answers it without a backend, and the
feature repository that calls it.

## Why It Is Built This Way

- **Features never see the transport.** A repository depends only on
  `ApiClient` (`lib/src/infrastructure/api/api_client.dart`), which returns
  feature models as `Result`. No Chopper, JSON or HTTP status reaches a
  feature, so a feature can't break when the wire format changes.
- **The adapter is swappable.** Everything wire-shaped — Chopper services,
  DTOs, interceptors, the converter, the mock — lives in the adapter under
  `lib/src/infrastructure/api/adapters/openapi/`. `apiClientProvider` is the
  single place that picks it.
- **Mock-first.** With `MOCK_API` on, `MockHttpClient` answers requests from
  `Fixtures` through the same interceptors, converter and DTOs as the real
  network. Build the endpoint against the agreed schema before the backend
  exists; when the backend ships, turning `MOCK_API` off is the only change.

See ADR-0018 and `docs/architecture/data-layer.md` (if present) for the full
rationale — this skill only covers the mechanics.

## 1. Start From the Contract

`contracts/openapi.json` is the source of truth for every call. Edit it first
(or replace it with the backend's spec), before touching code, so the code
follows the contract and not the other way round.

- Each operation's `operationId` becomes the method name everywhere
  (`ApiClient`, adapter, service).
- Each `components/schemas` entry becomes a DTO named after it
  (`MaintenanceInfo` → `MaintenanceInfoDto`).

If the backend hands you a Postman collection or a different spec, see
[references/conventions.md](references/conventions.md) for what to read in it.

**Stop and ask** before writing code if the spec changes a convention the
adapter implements once for every call: the auth scheme, public paths, token
refresh, a response envelope, the error body, or pagination. Each of those
has one home (listed in the reference), and changing it affects every
endpoint.

### Check Coverage

[scripts/api_coverage.py](scripts/api_coverage.py) ships with this skill (it
is not in the project's `scripts/`). Pass it the project directory:

```bash
python3 -I <this skill>/scripts/api_coverage.py <project_dir>
```

It prints one row per spec operation with `yes`/`no` for `ApiClient`, the
adapter and the mock (`internal` for the token refresh, which only the adapter
calls). Below the table it lists `ApiClient` methods with no `operationId` in
the spec, mock routes not in the spec, and `TODO(dev)` lines in the adapter.
It exits 0 when everything is covered, 1 otherwise, and 2 when the project or
spec isn't found. A freshly generated project exits 1 on purpose: the profile
call uses the placeholder path `GET /posts/1`, marked `TODO(dev)` in
`AccountService` until the real path is known. That line is expected; any
`**no**` cell or other line is work left to do.

## 2. Step 1 — Add the `ApiClient` Method

Add a method named after the `operationId` to `ApiClient`, returning the
feature model:

```dart
/// Fetches the maintenance status.
Future<Result<MaintenanceInfo, Failure>> getMaintenanceInfo();
```

Return a feature model, never a DTO, so features stay transport-free. If the
model doesn't exist yet, create it in the feature's `data/models/` first (see
`create-infrastructure`).

## 3. Step 2 — Add the DTO

Add the DTO to the area file in the adapter's `dtos/` folder
(`application_dto.dart` for the application area, `notification_dto.dart`,
`auth_dto.dart`…), with a doc comment naming its schema, and map it to the
model with a `toModel()` extension in the same file:

```dart
/// `MaintenanceInfo` schema in `contracts/openapi.json`.
@MappableClass()
class const MaintenanceInfoDto({
  final bool isMaintenance = false,
  final String? message,
}) with MaintenanceInfoDtoMappable {
  /// Creates a [MaintenanceInfoDto].
  this;
}

/// Maps [MaintenanceInfoDto] to the application feature model.
extension MaintenanceInfoDtoX on MaintenanceInfoDto {
  /// The [MaintenanceInfo] for this DTO.
  MaintenanceInfo toModel() =>
      MaintenanceInfo(isMaintenance: isMaintenance, message: message);
}
```

Only DTOs mirror the wire shape; the feature model keeps the names the app
wants. Map the schema faithfully:

- A property not in `required` is nullable or has its schema `default`
  (`isMaintenance = false` above, `message` nullable).
- A JSON key that isn't a valid or idiomatic Dart name:
  `@MappableField(key: 'is_maintenance') final bool isMaintenance`, or
  `@MappableClass(caseStyle: CaseStyle.snakeCase)` for the whole DTO.
- A string `enum`: a `@MappableEnum()` enum, with `@MappableValue('…')` on
  members whose wire value differs from the member name.
- `format: date-time` maps to `DateTime`.
- A request body gets its own DTO with a `fromModel` factory (see
  `LoginRequestDto.fromModel` in `auth_dto.dart`).

Mappers register automatically: `lib/src/_bootstrap/mappers.dart` initializes
every generated mapper in the package, so a new DTO needs no wiring. DTOs never
go in a package.

## 4. Step 3 — Add the Service Method

Add the Chopper method to the matching service in the adapter's `services/`:

```dart
/// Fetches the maintenance status.
@GET(path: '/api/v1/app/maintenance')
Future<Response<MaintenanceInfoDto>> getMaintenanceInfo();
```

Use `@Path`, `@Query` and `@Body` for parameters, and `Response<void>` for an
empty body. A new area gets a new service, registered in the `services:` list
of the adapter's `ChopperClient` (`OpenApiClient`) and exposed through a
private getter next to the others.

## 5. Step 4 — Implement It in the Adapter

Implement the method in `OpenApiClient` with `toResult`, which turns any
Chopper call into a `Result` so the adapter never needs `try/catch`:

```dart
@override
Future<Result<MaintenanceInfo, Failure>> getMaintenanceInfo() =>
    _application.getMaintenanceInfo().toResult((dto) => dto.toModel());
```

For a `void` call pass `(_) {}`: `_auth.logout().toResult((_) {})`.

## 6. Step 5 — Mock It

Add a route to `MockHttpClient` and a fixture to `Fixtures` (both in the
adapter's `mock/` folder), so the call works with `MOCK_API` on:

```dart
// mock_http_client.dart
'GET /api/v1/app/maintenance': (_) => _json(Fixtures.maintenanceInfo),

// fixtures.dart
/// `MaintenanceInfo`.
static const Map<String, dynamic> maintenanceInfo = {
  'isMaintenance': false,
  'message': 'Expected to be back in 2 hours @2:15PM IST',
};
```

- Routes are keyed `METHOD /path` exactly as in the spec; `{param}` segments
  match any value (`'DELETE /notifications/{id}'`).
- Shape the fixture like the schema, using the wire keys, so the mock
  exercises the real DTO mapping.
- Mutations are stateless: a `PATCH`/`DELETE` route answers `204` but doesn't
  change what later reads return (marking a notification read leaves the
  unread count unchanged). Keep the expected change in the feature's state if
  the UI needs it while mocked.
- A request with no route gets `501` with code `NOT_MOCKED` — a quick way to
  spot a missing mock while running the app.

## 7. Step 6 — Call It From the Repository

The repository passes straight through to `ApiClient`:

```dart
/// Fetches the maintenance status.
Future<Result<MaintenanceInfo, Failure>> getMaintenanceInfo() =>
    _api.getMaintenanceInfo();
```

with the client injected by its provider:
`ApplicationRepository(api: ref.watch(apiClientProvider), …)`. No mapping,
status checks or `try/catch` here — the adapter already did that.

## 8. Errors

Non-2xx responses and transport errors already arrive as an `ApiFailure`
carrying an `AppErrorCode` (`lib/src/infrastructure/error_codes.dart`):
`401` → `unauthorized`, `404` → `notFound`, `5xx` → `server`, a timeout or
lost connection → `timeout`/`network`. Don't wrap them in a feature
`Failure`; that is only for errors that don't come from the API.

When the backend sends its own error code in the error body, register an
`AppErrorCode` with that backend code as its second argument (e.g.
`auth401('auth401', 'INVALID_CREDENTIALS')`), plus its translations, as
described in the add-translations skill (§3). `AppErrorCode.fromBackend` then
maps it automatically.

## 9. Tests

How each layer is tested is described in the create-test skill (§3.1). For a
new endpoint, that means:

1. **Regenerate mocks first.** A new `ApiClient` method changes every
   generated `MockApiClient`, so run `melos run generate`.
2. **Repository test**: stub the new `ApiClient` method and test only what the
   repository adds.
3. **Adapter test**: in
   `test/src/infrastructure/api/adapters/openapi/openapi_client_test.dart`,
   add a case that the DTO maps to the expected model, and an error case if
   you mapped a new backend code. DTOs are tested through this, not on their
   own.

## 10. Going Live

When the backend is ready, set `BASE_URL` in `env/<flavor>.json` (no trailing
slash — service paths start with `/`) and turn `MOCK_API` off for that flavor.
Nothing in the features changes.

## 11. Verification

```bash
# Re-generate mappers, Chopper services and mocks
melos run generate

# Run static analysis and tests
melos run analyze
melos run coverage

# Spec, ApiClient, adapter and mock agree (only known TODO(dev) left)
python3 -I <this skill>/scripts/api_coverage.py <project_dir>
```
