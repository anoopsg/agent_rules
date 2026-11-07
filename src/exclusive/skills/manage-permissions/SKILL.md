---
name: manage-permissions
description: Extends role-based access control (UserRole, Permission, kRolePermissions) and gates routes or widgets by permission. Use when adding a permission or role, or restricting a route or UI element to some users.
---

# Permissions & RBAC Management Skill

This skill defines the process for extending the RBAC
(role-based access control) model and gating routes or UI
by capability. See
ADR-0014 (`docs/adr/`, if present) for the full design
rationale — this skill only covers the mechanics.

## 1. The Model

- `UserRole` (`lib/src/features/auth/_self/data/models/user_role.dart`):
  an enum of session roles (e.g. `guest`, `standard`).
- `Permission` (`lib/src/features/auth/_self/data/models/permission.dart`):
  an enum of capabilities (e.g. `settingsView`, `postsEdit`).
  Routes and widgets declare a `Permission`, never a
  `UserRole` directly.
- `kRolePermissions` (`lib/src/features/auth/_self/data/models/role_permissions.dart`):
  a single static `Map<UserRole, Set<Permission>>` — the one
  source of truth for what each role can do.
- `AppState.permissions` derives the current session's
  permission set from `kRolePermissions`; every consumer
  reads through this, never `kRolePermissions` directly.

### Where the Role Comes From

The backend sends the role as a string. The allowed values
are the `role` enum in `contracts/openapi.json`, and the API
adapter maps it to `UserRole` by name when it builds the
session (`grep -rn "asNameMap" lib/src/infrastructure`). An
unknown wire value falls back to `.standard`, so a role the
app doesn't know yet never breaks login.

To add a new role:

1. Add it to `UserRole` and run `melos run generate`
   (`UserRole` is a `@MappableEnum`).
2. Give it an entry in `kRolePermissions` (Step 2).
3. Add it to the `role` enum in `contracts/openapi.json`, so
   the wire name matches the enum member name.

Stop and ask if the backend spec doesn't define the role,
or names it differently from the enum member.

## 2. Step 1 — Add a New Permission

Add a member to the `Permission` enum:

```dart
enum Permission {
  settingsView,
  postsEdit,
  // ...
  reportsView,
}
```

## 3. Step 2 — Grant It to a Role

Update `kRolePermissions`:

```dart
const kRolePermissions = <UserRole, Set<Permission>>{
  .guest: {},
  .standard: {.settingsView, .postsEdit, .reportsView},
};
```

Changing what a role can do means editing this table only —
routes and widgets don't change.

## 4. Step 3 — Gate a Route

Pass `requiredPermission` on the route's `_AppRoute`
definition (see `manage-routes` for the general route-adding
process, including adding the route to `Routes._all`, which
is where the guard looks the permission up):

```dart
final class const _ReportsRoute() extends _AppRoute {
  this : super(
    path: '/reports',
    name: 'reports',
    requiredPermission: .reportsView,
  );

  @override
  Widget build(_, _) => const ReportsPage();
}
```

`PermissionGuard` (a `RouteGuard`, priority 40) enforces this
automatically at navigation time, redirecting to Home when
the session lacks the permission — no further wiring needed.

The first time any route sets `requiredPermission`, delete
the `// ignore: unused_element_parameter` line (and the
comment above it) on `requiredPermission` in `_AppRoute`;
it only exists because no route used the parameter yet.

## 5. Step 4 — Gate In-Place UI

For a widget that isn't a full route (e.g. hiding a button
rather than blocking navigation), use `PermissionGate` or the
`PermissionCheck` extension
(`lib/src/shared/permission_gate.dart`):

```dart
PermissionGate(
  permission: .reportsView,
  child: const ReportsButton(),
);

// or, inside a ConsumerWidget:
if (ref.hasPermission(.reportsView)) {
  // show the affordance
}
```

`PermissionGate` also takes an optional `fallback:` widget.
Hiding UI is cosmetic: anything that must be enforced also
needs a route gate or a server-side check.

## 6. Testing

Cover new permissions the same way as existing ones: verify
`kRolePermissions` grants/denies as expected, and that
`PermissionGuard`/`PermissionGate` redirect or hide correctly
for a role that lacks the permission. Extend
`test/src/routes/guards/permission_guard_test.dart` and
`test/src/shared/permission_gate_test.dart` rather than
adding new harnesses.
