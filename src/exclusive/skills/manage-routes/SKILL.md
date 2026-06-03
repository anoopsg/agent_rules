---
name: manage-routes
description: Use when asked to add, update, or group routes using GoRouter, or manage redirection guards.
---

# Routing Management Skill

This skill defines the process for adding, modifying, and guarding routes
in the project using GoRouter.

## 1. Directory Structure

Routing configurations are located in `lib/src/routes/`:

```text
lib/src/routes/
├── router.dart           # GoRouter config & authentication shells
├── router.g.dart         # Auto-generated routing code
├── router_listenable.dart# Listens to auth state changes to trigger redirects
└── routes.dart           # Static route definitions and builders
```

## 2. Step 1: Define the Route

Add a new static route definition inside [routes.dart](../../lib/src/routes/routes.dart).

Each route should be an `abstract final class` with `path`, `name`, and a static
`build` method:

```dart
abstract final class SettingsRoute {
  static const String path = '/settings';
  static const String name = 'settings';

  static Widget build(BuildContext context, GoRouterState state) =>
      const SettingsPage();
}
```

## 3. Step 2: Register the Route in router.dart

Add the route to the appropriate [ShellRoute] in [router.dart](../../lib/src/routes/router.dart):

- **openRoutes**: Accessible by any user on matching platforms (e.g. Splash,
  Maintenance, Update).
- **unauthenticatedRoutes**: Accessible ONLY when logged out. Redirects to Home
  if logged in (e.g. Login).
- **authenticatedRoutes**: Accessible ONLY when logged in. Redirects to Login
  if logged out (e.g. Profile, Settings).

### 3.1 Registration Example

Do **not** redefine the `ShellRoute`. Instead, add a `GoRoute` entry inside
the `routes` list of the appropriate existing shell variable in `router.dart`:

```dart
// Inside the existing authenticatedRoutes ShellRoute in appRouter()
GoRoute(
  name: SettingsRoute.name,
  path: SettingsRoute.path,
  builder: SettingsRoute.build,
),
```

## 4. Step 3: Re-generate Routing Code

The `appRouter` provider is annotated with `@Riverpod`. After any change to
router files, regenerate the `.g.dart` file by running:

```bash
melos run generate
```
