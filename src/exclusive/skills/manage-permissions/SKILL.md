---
name: manage-permissions
description: >-
  Use when asked to add a new permission, gate a route or
  widget by role/capability, or otherwise touch the RBAC
  model (UserRole, Permission, kRolePermissions).
---

# Permissions & RBAC Management Skill

This skill defines the process for extending the RBAC
(role-based access control) model and gating routes or UI
by capability. See
ADR-0014 for the full design rationale — this skill only covers the
mechanics.

## 1. The Model

- `UserRole` (`lib/src/infrastructure/auth/models/user_role.dart`):
  an enum of session roles (e.g. `guest`, `standard`).
- `Permission` (`lib/src/infrastructure/auth/models/permission.dart`):
  an enum of capabilities (e.g. `settingsView`, `postsEdit`).
  Routes and widgets declare a `Permission`, never a
  `UserRole` directly.
- `kRolePermissions` (`lib/src/infrastructure/auth/models/role_permissions.dart`):
  a single static `Map<UserRole, Set<Permission>>` — the one
  source of truth for what each role can do.
- `AppState.permissions` derives the current session's
  permission set from `kRolePermissions`; every consumer
  reads through this, never `kRolePermissions` directly.

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
  UserRole.guest: {},
  UserRole.standard: {
    Permission.settingsView,
    Permission.postsEdit,
    Permission.reportsView,
  },
};
```

## 4. Step 3 — Gate a Route

Pass `requiredPermission` on the route's `_AppRoute`
definition (see `manage-routes` for the general route-adding
process):

```dart
final class _ReportsRoute extends _AppRoute {
  const _ReportsRoute()
      : super(
          path: '/reports',
          name: 'reports',
          requiredPermission: Permission.reportsView,
        );

  @override
  Widget build(_, _) => const ReportsPage();
}
```

`PermissionGuard` (a `RouteGuard`, priority 40) enforces this
automatically at navigation time — no further wiring needed.

## 5. Step 4 — Gate In-Place UI

For a widget that isn't a full route (e.g. hiding a button
rather than blocking navigation), use `PermissionGate` or the
`PermissionCheck` extension
(`lib/src/shared/permission_gate.dart`):

```dart
PermissionGate(
  permission: Permission.reportsView,
  child: const ReportsButton(),
);

// or, inside a ConsumerWidget:
if (ref.hasPermission(Permission.reportsView)) {
  // show the affordance
}
```

## 6. Testing

Cover new permissions the same way as existing ones: verify
`kRolePermissions` grants/denies as expected, and that
`PermissionGuard`/`PermissionGate` redirect or hide correctly
for a role that lacks the permission.
