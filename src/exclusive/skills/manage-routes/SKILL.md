---
name: manage-routes
description: Adds and changes GoRouter routes, shells, bottom-nav tabs and redirect guards through the Routes registry. Use when adding a screen route, path parameters, navigation, or a gate or access guard.
---

# Routing Management Skill

This skill defines the process for adding, modifying,
and guarding routes using GoRouter with the `_AppRoute`
base class, `Routes` registry, and the priority-ordered
`GateGuard`/`RouteGuard` guards.

## 1. Directory Structure

```text
lib/src/routes/
├── guards/                # One file per GateGuard/RouteGuard + guards.dart barrel
├── router.dart            # GoRouter config, auth shells & resolveRedirect
├── router_listenable.dart # Auth-state refresh listener
└── routes.dart            # _AppRoute base + Routes registry
```

## 2. Route Architecture

### _AppRoute Base Class

Every route extends the private `_AppRoute` class which
holds `path`, `name`, and a `build` method. It also
provides `toGoRoute()` for zero-boilerplate registration:

```dart
abstract class const _AppRoute({
  required final String path,
  required final String name,
  final Permission? requiredPermission,
}) {
  Widget build(BuildContext context, GoRouterState state);

  GoRoute toGoRoute() {
    assert(
      Routes._all.contains(this),
      'Route "$name" must be added to Routes._all',
    );
    return GoRoute(name: name, path: path, builder: build);
  }
}
```

### Routes Registry

All routes are registered as `static const` fields in the
`Routes` class for autocomplete-friendly discovery, and
listed once more in `Routes._all`:

```dart
abstract final class Routes {
  static const home = _HomeRoute();
  static const login = _LoginRoute();
  // ...

  static const List<_AppRoute> _all = [home, login, /* ... */];
}
```

`_all` is what `PermissionGuard` searches (through
`Routes.requiredPermissionFor`) to find a route's
`requiredPermission`, so a route missing from it would
silently skip its permission check. `toGoRoute()` asserts
membership in debug builds to catch this.

## 3. Step 1 — Define a New Route

Add a `final class` extending `_AppRoute` at the bottom of
`lib/src/routes/routes.dart`:

```dart
final class const _SearchRoute() extends _AppRoute {
  this : super(path: '/search', name: 'search');

  @override
  Widget build(_, _) => const SearchPage();
}
```

`routes.dart` imports pages only through
`lib/src/features/features.dart`, so export the page from
its feature barrel and make sure that barrel is exported
from `features.dart`.

For routes with path parameters, extract them from
`GoRouterState`:

```dart
final class const _DetailRoute() extends _AppRoute {
  this : super(path: '/detail/:id', name: 'detail');

  @override
  Widget build(_, GoRouterState state) {
    final id = state.pathParameters['id']!;
    return DetailPage(id: id);
  }
}
```

If the route should be gated by a capability rather than
just login state, pass `requiredPermission`:

```dart
final class const _SettingsRoute() extends _AppRoute {
  this : super(
    path: '/settings',
    name: 'settings',
    requiredPermission: .settingsView,
  );

  @override
  Widget build(_, _) => const SettingsPage();
}
```

Until a route uses it, `requiredPermission` in `_AppRoute`
carries an `// ignore: unused_element_parameter` line (and
its comment); delete them with the first route that sets
it. See `manage-permissions` for the full RBAC model.

## 4. Step 2 — Register in Routes

Add a `static const` entry in the `Routes` class inside
`lib/src/routes/routes.dart`, and add it to `_all`:

```dart
abstract final class Routes {
  // ... existing routes
  static const search = _SearchRoute();

  static const List<_AppRoute> _all = [
    // ... existing routes
    search,
  ];
}
```

## 5. Step 3 — Add to the Router

Add the route to the appropriate shell in
`lib/src/routes/router.dart` using `toGoRoute()`:

```dart
Routes.search.toGoRoute(),
```

### Authentication Shells

| Shell | Access | Redirect |
|---|---|---|
| `openRoutes` | Any user, platform-gated | None |
| `unauthenticatedRoutes` | Logged-out only | → `/` if logged in |
| `authenticatedRoutes` | Logged-in only | → `/login` if logged out |

### Route Guards

Cross-cutting gates that don't belong to a single shell come
in two shapes (`lib/src/routes/guards/route_guard.dart`):

- **`GateGuard`** — owns one exclusive full-screen route
  (`path`) and just answers whether it's currently active
  (`isActive(AppState app)`), with no knowledge of the
  current location. The router sorts `gateGuards` by
  `priority` and acts on **only the first active one**
  per redirect pass — never comparing multiple gates against
  the path itself — so two gates can't fight over the screen.
- **`RouteGuard`** — a per-route access check,
  `redirect(AppState app, GoRouterState state)`, evaluated
  only once every gate has resolved. Access guards run in
  `accessGuards` list order; their `priority` is not used
  for sorting, so place a new one deliberately.
  `PermissionGuard` is the example to mirror.

List the current guards and read each one's `priority` and
doc comment before adding another:

```bash
grep -rn "extends GateGuard\|extends RouteGuard" lib/src/routes/guards
```

Platform-specific gates decide inside `isActive` with
`kIsWeb`. For example, `OnboardingGuard` is mobile-only,
and it also respects `FeatureFlags.onboardingEnabled`:
when the flag is off, `OnboardingRepository` reports
onboarding as completed, so the gate never activates.

To add a new full-screen gate, add a file implementing
`GateGuard`, export it from `guards/guards.dart`, and add one
entry in the `gateGuards` list in `router.dart` — existing
guards never need to change, and the router's stale-gate
fallback picks it up automatically since it derives from
`gateGuards` itself, not a separate path list. Give it a
`priority` no other gate uses (lower wins), and register
its route in `openRoutes` and `Routes._all`. To add a new
per-route access check, implement `RouteGuard` instead and
add it to `accessGuards`. See ADR-0008 for the original
guard design and ADR-0016 for why gates are arbitrated this
way (`docs/adr/`, if present) — this skill only covers the
mechanics.

### `resolveRedirect` & the Splash Hold

The top-level redirect lives in `resolveRedirect` in
`router.dart` and runs in this order:

1. **Not ready yet (mobile only)**: until `AppState.isReady`,
   any navigation away from splash (e.g. a cold-start deep
   link) is held on `/splash?from=<target>`. Web skips this.
2. **Active gate**: the first active gate owns the screen.
   The redirect goes to the gate's bare path, so a held
   `from` is dropped — a deep link held through onboarding
   or a forced update lands on Home afterwards. This is
   known behavior; keep it in mind rather than working
   around it inside a gate.
3. **Stale gate**: with no gate active, a user still on a
   gate screen bounces to `from` (if present) or Home.
4. **Access guards** decide everything else.

Auth redirects stay on each shell's `redirect`; don't add
auth checks to the top-level redirect.

### `_landingRoute()` & Platform Routing

The `_landingRoute()` function handles platform-specific
layouts. On mobile the landing page uses a
`StatefulShellRoute.indexedStack` with bottom nav
branches (home, explore, notifications, profile). On web
it returns a single `Routes.home.toGoRoute()`.

To add a new bottom-nav tab, add the route to the
`branches` list inside `_landingRoute()`, and a matching
`NavigationDestination` at the same index in the landing
shell (`grep -rn "NavigationDestination(" lib/src/features/landing`).

## 6. Step 4 — Re-generate

The `appRouter` provider is annotated with `@Riverpod`.
After any change, regenerate the `.g.dart` file:

```bash
melos run generate
```

## 7. Navigation in Code

```dart
context.go(Routes.settings.path);
context.push(Routes.settings.path);
context.goNamed(Routes.settings.name);
```

## 8. Testing

Extend the existing routing tests rather than adding new
harnesses:

- `test/src/routes/redirect_test.dart` — `resolveRedirect`
  with fake gates: the splash hold and `from`, gate
  arbitration, the stale-gate bounce. Extend it when you
  change redirect ordering.
- `test/src/routes/guards/gate_guards_test.dart` — each
  gate's active/inactive cases and the unique priorities.
  Add a new gate here, and to the gate list in
  `test/src/routes/guards/permission_guard_test.dart`.
- A new `RouteGuard` or restricted route: cover both the
  allowed and the redirected case.
