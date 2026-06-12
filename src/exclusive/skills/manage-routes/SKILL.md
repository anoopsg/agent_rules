---
name: manage-routes
description: >-
  Use when asked to add, update, or group routes using
  GoRouter, or manage redirection guards.
---

# Routing Management Skill

This skill defines the process for adding, modifying,
and guarding routes using GoRouter with the `_AppRoute`
base class, `Routes` registry, and `_RouteComposer`.

## 1. Directory Structure

```text
lib/src/routes/
├── router.dart            # GoRouter config & auth shells
├── router.g.dart          # Auto-generated (Riverpod)
├── router_listenable.dart # Auth-state refresh listener
└── routes.dart            # _AppRoute base + Routes registry
```

## 2. Route Architecture

### _AppRoute Base Class

Every route extends the private `_AppRoute` class which
holds `path`, `name`, and a `build` method. It also
provides `toGoRoute()` for zero-boilerplate registration:

```dart
abstract class _AppRoute {
  const _AppRoute({required this.path, required this.name});
  final String path;
  final String name;

  Widget build(BuildContext context, GoRouterState state);

  GoRoute toGoRoute() => GoRoute(
    name: name,
    path: path,
    builder: build,
  );
}
```

### Routes Registry

All routes are registered as `static const` fields in the
`Routes` class for autocomplete-friendly discovery:

```dart
abstract final class Routes {
  static const home = _HomeRoute();
  static const login = _LoginRoute();
  // ...
}
```

## 3. Step 1 — Define a New Route

Add a `final class` extending `_AppRoute` at the bottom of
[routes.dart](../../lib/src/routes/routes.dart):

```dart
final class _SearchRoute extends _AppRoute {
  const _SearchRoute()
      : super(path: '/search', name: 'search');

  @override
  Widget build(_, _) => const SearchPage();
}
```

For routes with path parameters, extract them from
`GoRouterState`:

```dart
final class _DetailRoute extends _AppRoute {
  const _DetailRoute()
      : super(path: '/detail/:id', name: 'detail');

  @override
  Widget build(_, GoRouterState state) {
    final id = state.pathParameters['id']!;
    return DetailPage(id: id);
  }
}
```

## 4. Step 2 — Register in Routes

Add a `static const` entry in the `Routes` class inside
[routes.dart](../../lib/src/routes/routes.dart):

```dart
abstract final class Routes {
  // ... existing routes
  static const search = _SearchRoute();
}
```

## 5. Step 3 — Add to the Router

Add the route to the appropriate shell in
[router.dart](../../lib/src/routes/router.dart) using
`toGoRoute()`:

```dart
Routes.search.toGoRoute(),
```

### Authentication Shells

| Shell | Access | Redirect |
|---|---|---|
| `openRoutes` | Any user, platform-gated | None |
| `unauthenticatedRoutes` | Logged-out only | → `/` if logged in |
| `authenticatedRoutes` | Logged-in only | → `/login` if logged out |

### _RouteComposer & Platform Routing

The `_RouteComposer` class handles platform-specific
layouts. On mobile the landing page uses a
`StatefulShellRoute.indexedStack` with bottom nav
branches (home, explore, notifications, profile). On web
it returns a single `Routes.home.toGoRoute()`.

To add a new bottom-nav tab, add the route to the
`branches` list inside `_RouteComposer.landing`.

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
